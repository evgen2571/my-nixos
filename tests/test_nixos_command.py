#!/usr/bin/env python3
"""Check command arguments without building or activating anything."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class CommandTests(unittest.TestCase):
    def test_private_sources(self):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            tools = directory / "bin"
            tools.mkdir()
            nix = tools / "nix"
            nix.write_text(
                "#!/usr/bin/env python3\nimport json, sys\nprint(json.dumps(sys.argv[1:]))\n"
            )
            nix.chmod(0o755)
            private = directory / "private ' \" \\ $NAME # % ? π"
            private.mkdir()
            (private / "flake.nix").write_text("{ outputs = _: {}; }")
            env = dict(
                os.environ,
                PATH=f"{tools}:{os.environ['PATH']}",
                MY_NIXOS_PRIVATE=str(private),
            )

            def invoke(*flags):
                return subprocess.run(
                    [
                        "bash",
                        str(ROOT / "lib/nixos-command.sh"),
                        "build",
                        "new-host",
                        *flags,
                    ],
                    env=env,
                    capture_output=True,
                    text=True,
                )

            result = invoke()
            self.assertEqual(result.returncode, 0, result.stderr)
            args = json.loads(result.stdout)
            self.assertIn("path:", args[args.index("private") + 1])
            reference = args[args.index("private") + 1]
            quoted = json.dumps(reference, ensure_ascii=False).replace("${", r"\${")
            parsed = subprocess.run(
                [
                    "nix-instantiate",
                    "--eval",
                    "--strict",
                    "--json",
                    "--expr",
                    f"builtins.parseFlakeRef {quoted}",
                ],
                text=True,
                capture_output=True,
            )
            self.assertEqual(parsed.returncode, 0, parsed.stderr)
            self.assertEqual(json.loads(parsed.stdout)["path"], str(private))
            self.assertIn("--no-write-lock-file", args)
            explicit = invoke("--override-input", "private", "path:/explicit")
            self.assertEqual(json.loads(explicit.stdout).count("--override-input"), 1)
            subprocess.run(["git", "init", "-q", str(private)], check=True)
            dirty = invoke()
            self.assertNotEqual(dirty.returncode, 0)
            subprocess.run(["git", "-C", str(private), "add", "."], check=True)
            subprocess.run(
                [
                    "git",
                    "-C",
                    str(private),
                    "-c",
                    "user.name=Test",
                    "-c",
                    "user.email=test@example.invalid",
                    "commit",
                    "-qm",
                    "fixture",
                ],
                check=True,
            )
            clean = invoke()
            self.assertEqual(clean.returncode, 0, clean.stderr)
            self.assertIn("git+file://", clean.stdout)
            (private / "flake.nix").write_text("changed")
            self.assertNotEqual(invoke().returncode, 0)
            env["MY_NIXOS_PRIVATE"] = str(directory / "missing")
            self.assertNotEqual(invoke().returncode, 0)
            broken = directory / "broken"
            broken.mkdir()
            (broken / "flake.nix").write_text("{ outputs = _: {}; }")
            (broken / ".git").write_text("gitdir: /does/not/exist\n")
            env["MY_NIXOS_PRIVATE"] = str(broken)
            self.assertNotEqual(invoke().returncode, 0)


if __name__ == "__main__":
    unittest.main()
