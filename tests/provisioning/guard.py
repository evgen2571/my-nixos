"""Exercise the real provisioning guard with fake disk metadata; never use a disk."""

import os
from pathlib import Path
import subprocess
import shutil
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[2]
DEVICE = "/dev/disk/by-id/test-system"


class GuardTests(unittest.TestCase):
    def run_guard(self, *args, answer="", **metadata):
        with tempfile.TemporaryDirectory() as directory:
            scratch = Path(directory)
            commands = {
                "readlink": '''
count=0
[[ ! -f $COUNTER ]] || read -r count < "$COUNTER"
echo "$((count + 1))" > "$COUNTER"
if [[ $count -ge 2 && ${CHANGE_IDENTITY:-0} == 1 ]]; then
    echo /dev/vdc
else
    echo "${RESOLVED:-/dev/vdb}"
fi
''',
                "id": 'echo "${USER_ID:-0}"',
                "lsblk": """
[[ ${LSBLK_FAIL:-0} == 0 ]] || exit 1
case "$*" in
  *TYPE*) echo "${DISK_TYPE:-disk}" ;;
  *MOUNTPOINTS*) printf '%s\\n' "${MOUNTS:-}" ;;
  *RO*) echo "${READ_ONLY:-0}" ;;
esac
""",
                "disko": 'printf "DISKO"; printf " <%s>" "$@"; echo',
            }
            for name, text in commands.items():
                path = scratch / name
                path.write_text(f"#!{shutil.which('bash')}\n" + text)
                path.chmod(0o755)
            source = (ROOT / "provisioning/provision-disk.sh").read_text()
            script = scratch / "guard.sh"
            script.write_text(
                source.replace("@disko@", str(scratch / "disko")).replace(
                    "@layout@", "/test/layout.nix"
                )
            )
            env = dict(os.environ, PATH=f"{scratch}:{os.environ['PATH']}", COUNTER=str(scratch / "counter"), **metadata)
            return subprocess.run(
                ["bash", str(script), *args],
                input=answer,
                capture_output=True,
                text=True,
                env=env,
                timeout=5,
            )

    def assert_refused(self, *args, reason, **kwargs):
        result = self.run_guard(*args, **kwargs)
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertIn(reason, result.stderr)
        self.assertNotIn("DISKO", result.stdout)

    def test_missing_and_unknown_selection(self):
        self.assert_refused(reason="Usage:")
        self.assert_refused("apply", "unknown", DEVICE, reason="host")
        self.assert_refused("destroy", "pc", DEVICE, reason="Usage:")

    def test_requires_stable_whole_disk(self):
        for device in ["/dev/sda", "/dev/disk/by-id/../sda", "", "/dev/loop0"]:
            with self.subTest(device=device):
                self.assert_refused("apply", "pc", device, reason="by-id")
        self.assert_refused("apply", "pc", DEVICE, DISK_TYPE="part", reason="whole disk")

    def test_refuses_mounted_swap_and_read_only_disks(self):
        for mounts in ["/", "/mnt", "[SWAP]", "\n\n/srv/storage\n"]:
            with self.subTest(mounts=mounts):
                self.assert_refused("apply", "server", DEVICE, MOUNTS=mounts, reason="in use")
        self.assert_refused("apply", "pc", DEVICE, READ_ONLY="1", reason="read-only")

    def test_requires_root_and_exact_confirmation(self):
        self.assert_refused("apply", "pc", DEVICE, USER_ID="1000", reason="root")
        for answer in ["", "yes\n", f"ERASE laptop {DEVICE}\n", "ERASE pc /dev/sda\n"]:
            with self.subTest(answer=answer):
                self.assert_refused("apply", "pc", DEVICE, answer=answer, reason="confirmation")

    def test_metadata_failure_and_device_change_refuse_apply(self):
        self.assert_refused("apply", "pc", DEVICE, LSBLK_FAIL="1", reason="cannot inspect")
        self.assert_refused(
            "apply", "pc", DEVICE, CHANGE_IDENTITY="1",
            answer=f"ERASE pc {DEVICE}\n", reason="identity changed",
        )

    def test_preview_cannot_execute_formatting(self):
        result = self.run_guard("preview", "pc", DEVICE, USER_ID="1000")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("<--dry-run>", result.stdout)
        self.assertNotIn("<--yes-wipe-all-disks>", result.stdout)

    def test_confirmed_apply_passes_only_selected_host_and_disk(self):
        for host in ["pc", "laptop", "server"]:
            with self.subTest(host=host):
                result = self.run_guard(
                    "apply", host, DEVICE, answer=f"ERASE {host} {DEVICE}\n"
                )
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertIn("<--mode> <destroy,format,mount>", result.stdout)
                self.assertIn(f"<--argstr> <host> <{host}>", result.stdout)
                self.assertIn(f"<--argstr> <device> <{DEVICE}>", result.stdout)
                self.assertIn("<--yes-wipe-all-disks>", result.stdout)


if __name__ == "__main__":
    unittest.main()
