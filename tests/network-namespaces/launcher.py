"""Run only inside `unshare --user --map-auto --map-root-user --mount --net`.
Exercises real C entry, mounts, identities and capability drops with a fixed
sudo adapter. Production sudo policy and real VPN readiness need live checks.
"""
import json
import os
from pathlib import Path
import subprocess
import sys
import unittest

launcher = Path(sys.argv.pop(1))
tools = Path(sys.argv.pop(1))
os.environ["PATH"] = str(tools / "bin") + ":" + os.environ["PATH"]
uid_map = Path("/proc/self/uid_map").read_text().splitlines()
if os.getuid() != 0 or len(uid_map) < 2 or int(uid_map[0].split()[1]) == 0:
    raise SystemExit("This fixture requires an isolated, subordinate-ID user namespace")


def run(*args):
    return subprocess.run(args, check=True, capture_output=True, text=True)



# All /etc and /run changes below are confined to private tmpfs mounts.
run("mount", "--make-rprivate", "/")
run("mount", "-t", "tmpfs", "tmpfs", "/etc")
run("mount", "-t", "tmpfs", "tmpfs", "/run")
Path("/etc/passwd").write_text("root:x:0:0::/:/bin/sh\nprobe:x:1000:100::/run/project:/bin/sh\n")
Path("/etc/group").write_text("root:x:0:\nusers:x:100:probe\nproject:x:102:probe\n")
Path("/etc/nsswitch.conf").write_text("passwd: files\ngroup: files\nhosts: files dns\n")
Path("/etc/resolv.conf").write_text("nameserver 192.0.2.55\n")
Path("/run/nscd").mkdir()
Path("/run/netns").mkdir()
runtime = Path("/run/network-namespaces/vpn")
runtime.mkdir(parents=True)
(runtime / "empty-nscd").mkdir()
(runtime / "resolv.conf").write_text("nameserver 10.255.255.2\n")
(runtime / "nsswitch.conf").write_text(Path("/etc/nsswitch.conf").read_text())
(runtime / "ready").touch()
(runtime / "resolv.conf").chmod(0o644)
(runtime / "nsswitch.conf").chmod(0o644)
run("ip", "netns", "add", "vpn")
expected_ns = run("ip", "netns", "exec", "vpn", "readlink", "/proc/self/ns/net").stdout.strip()
project = Path("/run/project")
project.mkdir()
(project / "project.txt").write_text("project access preserved")
os.chown(project, 1000, 100)
(project / "project.txt").chmod(0o644)
user_env = dict(os.environ, TEST_VALUE="one\ntwo = three", CODEX_HOME="/run/account-two",
                SSH_AUTH_SOCK="/run/agent socket", SUDO_UID="untrusted-original-value")


class LauncherTests(unittest.TestCase):
    def invoke(self, *args):
        return subprocess.run([str(launcher / "bin/namespace-launch"), *args],
                              cwd=project, env=user_env, input="stdin payload\n",
                              capture_output=True, text=True)

    def test_identity_io_environment_files_and_children(self):
        args = ["space arg", "", "--flag", "line\nbreak"]
        p = self.invoke("probe", *args)
        self.assertEqual(p.returncode, 37, p.stderr)
        data = json.loads(p.stdout)
        self.assertEqual((data["uid"], data["gid"]), (1000, 100))
        self.assertIn(102, data["groups"])
        self.assertEqual(data["args"], args)
        self.assertEqual(data["stdin"], "stdin payload\n")
        self.assertEqual(data["cwd"], str(project))
        self.assertEqual(data["project"], "project access preserved")
        self.assertEqual(data["netns"], expected_ns)
        self.assertEqual(data["child"]["netns"], expected_ns)
        self.assertEqual(data["child"]["uid"], 1000)
        self.assertEqual(data["dns"], "nameserver 10.255.255.2\n")
        for key in ["CapInh", "CapPrm", "CapEff", "CapBnd", "CapAmb"]:
            self.assertEqual(int(data["status"][key], 16), 0, key)
        self.assertEqual(data["status"]["NoNewPrivs"], "1")
        self.assertEqual(data["env"], {k: user_env[k] for k in data["env"]})
        self.assertEqual((project / "created.txt").stat().st_uid, 1000)
        self.assertEqual(Path("/etc/resolv.conf").read_text(), "nameserver 192.0.2.55\n")

    def test_unregistered_target_is_rejected(self):
        p = self.invoke("/bin/sh", "-c", "id")
        self.assertEqual(p.returncode, 125)
        self.assertIn("unregistered application", p.stderr)
        self.assertEqual(p.stdout, "")

    def test_not_ready_does_not_execute_app(self):
        (runtime / "ready").unlink()

        try:
            p = self.invoke("probe")
            self.assertEqual(p.returncode, 125)
            self.assertIn("refusing host-network fallback", p.stderr)
            self.assertEqual(p.stdout, "")
        finally:
            (runtime / "ready").touch()

    def test_missing_namespace_does_not_execute_app(self):
        global expected_ns
        run("ip", "netns", "delete", "vpn")

        try:
            p = self.invoke("probe")
            self.assertEqual(p.returncode, 125)
            self.assertEqual(p.stdout, "")
        finally:
            run("ip", "netns", "add", "vpn")
            expected_ns = run("ip", "netns", "exec", "vpn", "readlink", "/proc/self/ns/net").stdout.strip()

    def test_root_owned_resolver_is_required(self):
        (runtime / "resolv.conf").chmod(0o666)

        try:
            p = self.invoke("probe")
            self.assertEqual(p.returncode, 125)
            self.assertIn("unsafe ownership or permissions", p.stderr)
        finally:
            (runtime / "resolv.conf").chmod(0o644)

    def test_signal_and_exit_status(self):
        with subprocess.Popen([str(launcher / "bin/namespace-launch"), "probe", "--wait"],
                              cwd=project, env=user_env, stdout=subprocess.PIPE,
                              stderr=subprocess.PIPE, text=True) as p:
            self.assertEqual(p.stdout.readline().strip(), "ready")
            p.terminate()
            self.assertEqual(p.wait(timeout=5), 42, p.stderr.read())


unittest.main()
