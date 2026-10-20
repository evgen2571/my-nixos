#!/usr/bin/env python3
"""Exercise helper argument forwarding with inert command doubles."""

import json
import os
from pathlib import Path
import shutil
import sys
import subprocess
import tempfile
import unittest
from urllib.parse import quote

ROOT = Path(__file__).resolve().parents[2]
FLAGS = [
    "--override-input",
    "private",
    "git+file:///private checkout?rev=fixture",
    "--no-write-lock-file",
]


class Helpers(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.directory = Path(self.temp.name)
        self.log = self.directory / "calls.jsonl"
        for name in ["nix", "sudo", "nixos-rebuild"]:
            tool = self.directory / name
            tool.write_text(
                "#!"
                + sys.executable
                + '\nimport json, os, sys\nwith open(os.environ["TEST_COMMAND_LOG"], "a") as log: log.write(json.dumps(sys.argv[1:])+"\\n")\n'
            )
            tool.chmod(0o755)
        self.env = os.environ | {
            "PATH": str(self.directory) + ":" + os.environ["PATH"],
            "TEST_COMMAND_LOG": str(self.log),
            "TERM": "dumb",
            "MY_NIXOS_PRIVATE": "",
        }

    def private_checkout(self):
        directory = self.directory / "private checkout #1?%"
        directory.mkdir()
        subprocess.run(["git", "init", "-q", str(directory)], check=True)
        (directory / "flake.nix").write_text("{ outputs = _: {}; }")
        subprocess.run(["git", "-C", str(directory), "add", "flake.nix"], check=True)
        subprocess.run([
            "git", "-C", str(directory), "-c", "user.name=fixture",
            "-c", "user.email=fixture@example.invalid", "-c", "commit.gpgsign=false",
            "commit", "-qm", "fixture",
        ], check=True)
        revision = subprocess.check_output(
            ["git", "-C", str(directory), "rev-parse", "HEAD"], text=True
        ).strip()
        return directory, revision

    def test_configured_checkout_pins_commit_for_all_actions(self):
        directory, revision = self.private_checkout()
        self.env["MY_NIXOS_PRIVATE"] = str(directory)
        for action in ["check", "build", "dry", "switch", "boot"]:
            self.log.unlink(missing_ok=True)
            args = [action] + ([] if action == "check" else ["nixos-server"])
            subprocess.run(
                ["bash", str(ROOT / "lib/nixos-command.sh")] + args,
                cwd=ROOT, env=self.env, check=True, capture_output=True,
            )
            call = json.loads(self.log.read_text().splitlines()[-1])
            prefix = {
                "check": ["flake", "check"],
                "build": ["build", ".#nixosConfigurations.nixos-server.config.system.build.toplevel"],
                "dry": ["nixos-rebuild", "dry-build", "--flake", ".#nixos-server"],
                "switch": ["nixos-rebuild", "switch", "--flake", ".#nixos-server"],
                "boot": ["nixos-rebuild", "boot", "--flake", ".#nixos-server"],
            }[action]
            self.assertEqual(call[:len(prefix)], prefix)
            i = call.index("--override-input")
            self.assertEqual(call[i + 1:i + 3], ["private", f"git+file://{quote(str(directory))}?rev={revision}"])
            self.assertIn("--no-write-lock-file", call)

    def test_missing_or_dirty_private_checkout_refuses_commands(self):
        directory, _ = self.private_checkout()
        (directory / "uncommitted.nix").write_text("{}")
        for path in [directory, self.directory / "missing"]:
            self.env["MY_NIXOS_PRIVATE"] = str(path)
            result = subprocess.run(
                ["bash", str(ROOT / "lib/nixos-command.sh"), "switch", "nixos-pc"],
                cwd=ROOT, env=self.env, capture_output=True,
            )
            self.assertNotEqual(result.returncode, 0)
            self.assertFalse(self.log.exists())

    def test_explicit_input_ignores_unselected_local_checkout(self):
        self.env["MY_NIXOS_PRIVATE"] = "/missing/unselected-checkout"
        subprocess.run(
            ["bash", str(ROOT / "lib/nixos-command.sh"), "build", "nixos-pc"] + FLAGS,
            cwd=ROOT, env=self.env, check=True, capture_output=True,
        )
        call = json.loads(self.log.read_text().splitlines()[-1])
        self.assertEqual(call.count("--override-input"), 1)
        self.assertEqual(call[-len(FLAGS):], FLAGS)

    @unittest.skipUnless(shutil.which("just"), "just required")
    def test_just_loads_local_dotenv(self):
        directory, revision = self.private_checkout()
        project = self.directory / "project"
        (project / "lib").mkdir(parents=True)
        shutil.copy(ROOT / "justfile", project)
        shutil.copy(ROOT / "lib/nixos-command.sh", project / "lib")
        (project / ".env").write_text(f'MY_NIXOS_PRIVATE="{directory}"\n')
        env = self.env.copy()
        env.pop("MY_NIXOS_PRIVATE")
        subprocess.run(["just", "build-pc"], cwd=project, env=env, check=True, capture_output=True)
        call = json.loads(self.log.read_text().splitlines()[-1])
        self.assertIn(f"git+file://{quote(str(directory))}?rev={revision}", call)

    @unittest.skipUnless(shutil.which("just"), "just required")
    def test_just_aliases_and_actions_preserve_flags(self):
        for recipe in ["build-pc", "dry-lp", "switch-server", "boot"]:
            self.log.unlink(missing_ok=True)
            args = [shutil.which("just"), "--justfile", str(ROOT / "justfile"), recipe]
            if recipe == "boot":
                args += ["nixos-pc"]
            subprocess.run(
                args + FLAGS, cwd=ROOT, env=self.env, check=True, capture_output=True
            )
            call = json.loads(self.log.read_text().splitlines()[-1])
            self.assertEqual(call[-len(FLAGS) :], FLAGS)

    @unittest.skipUnless(shutil.which("fish"), "fish required")
    def test_fish_helpers_preserve_flags(self):
        import shlex

        for helper in ["nb", "nd", "nsw", "nboot"]:
            self.log.unlink(missing_ok=True)
            command = (
                "source "
                + shlex.quote(str(ROOT / "config/fish/conf.d/nixos-hosts.fish"))
                + "; "
                + shlex.join([helper, "nixos-pc"] + FLAGS)
            )
            subprocess.run(
                [shutil.which("fish"), "--no-config", "--interactive", "-c", command],
                cwd=ROOT,
                env=self.env,
                check=True,
                capture_output=True,
            )
            call = json.loads(self.log.read_text().splitlines()[-1])
            self.assertEqual(call[-len(FLAGS) :], FLAGS)


if __name__ == "__main__":
    unittest.main()
