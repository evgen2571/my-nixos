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
        }

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
