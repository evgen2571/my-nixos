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

        for name in ["nix", "nixos-rebuild"]:
            tool = self.directory / name
            tool.write_text(
                "#!"
                + sys.executable
                + '\nimport json, os, sys\nwith open(os.environ["TEST_COMMAND_LOG"], "a") as log: log.write(json.dumps(sys.argv[1:])+"\\n")\n'
            )
            tool.chmod(0o755)

        sudo = self.directory / "sudo"
        sudo.write_text(
            "#!" + sys.executable
            + "\nimport sys\nsys.exit('fetching must run as the invoking user')\n"
        )
        sudo.chmod(0o755)

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
                "dry": ["dry-build", "--sudo", "--flake", ".#nixos-server"],
                "switch": ["switch", "--sudo", "--flake", ".#nixos-server"],
                "boot": ["boot", "--sudo", "--flake", ".#nixos-server"],
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
        for source in ["/missing/unselected-checkout", "git@github.com/example/private"]:
            self.env["MY_NIXOS_PRIVATE"] = source
            subprocess.run(
                ["bash", str(ROOT / "lib/nixos-command.sh"), "build", "nixos-pc"] + FLAGS,
                cwd=ROOT, env=self.env, check=True, capture_output=True,
            )
            call = json.loads(self.log.read_text().splitlines()[-1])
            self.assertEqual(call.count("--override-input"), 1)
            self.assertEqual(call[-len(FLAGS):], FLAGS)
            self.assertNotIn("--refresh", call)

    def test_remote_sources_default_main_and_preserve_explicit_refs(self):
        base = "git+ssh://git@github.com/example/private"

        for source, expected in [
            ("git@github.com/example/private", base + "?ref=main"),
            ("git@github.com/example/private?ref=release/private", base + "?ref=release/private"),
            (base, base + "?ref=main"),
            (base + "?ref=stable", base + "?ref=stable"),
            (base + "?rev=" + "a" * 40, base + "?rev=" + "a" * 40),
        ]:
            for action in ["check", "build", "dry", "switch", "boot"]:
                with self.subTest(source=source, action=action):
                    self.env["MY_NIXOS_PRIVATE"] = source
                    args = [action] + ([] if action == "check" else ["nixos-pc"])
                    subprocess.run(
                        ["bash", str(ROOT / "lib/nixos-command.sh")] + args,
                        cwd=ROOT, env=self.env, check=True, capture_output=True,
                    )
                    call = json.loads(self.log.read_text().splitlines()[-1])
                    i = call.index("--override-input")
                    self.assertEqual(call[i + 1:i + 3], ["private", expected])
                    self.assertEqual(call.count("--refresh"), 1)
                    self.assertIn("--no-write-lock-file", call)
                    self.assertEqual("--sudo" in call, action in ["dry", "switch", "boot"])

    @unittest.skipUnless(shutil.which("just"), "just required")
    def test_just_loads_local_dotenv(self):
        directory, revision = self.private_checkout()
        project = self.directory / "project"
        (project / "lib").mkdir(parents=True)
        shutil.copy(ROOT / "justfile", project)
        shutil.copy(ROOT / "lib/nixos-command.sh", project / "lib")
        env = self.env.copy()
        env.pop("MY_NIXOS_PRIVATE")

        for source, expected in [
            (str(directory), f"git+file://{quote(str(directory))}?rev={revision}"),
            ("git@github.com/example/private", "git+ssh://git@github.com/example/private?ref=main"),
            ("git@github.com/example/private?ref=release/private", "git+ssh://git@github.com/example/private?ref=release/private"),
        ]:
            (project / ".env").write_text(f'MY_NIXOS_PRIVATE="{source}"\n')
            subprocess.run(["just", "build-pc"], cwd=project, env=env, check=True, capture_output=True)
            call = json.loads(self.log.read_text().splitlines()[-1])
            self.assertIn(expected, call)

    @unittest.skipUnless(shutil.which("just"), "just required")
    def test_just_aliases_and_actions_preserve_flags(self):
        (self.directory / "bash").symlink_to(shutil.which("bash"))
        env = self.env | {"PATH": str(self.directory)}
        self.assertIsNone(shutil.which("just", path=env["PATH"]))

        for recipe in [
            f"{action}-{host}"
            for action in ["build", "dry", "switch"]
            for host in ["pc", "lp", "server"]
        ] + ["build", "dry", "switch", "boot"]:
            self.log.unlink(missing_ok=True)
            args = [shutil.which("just"), "--justfile", str(ROOT / "justfile"), recipe]
            if "-" not in recipe:
                args += ["nixos-pc"]
            subprocess.run(
                args + FLAGS, cwd=ROOT, env=env, check=True, capture_output=True
            )
            call = json.loads(self.log.read_text().splitlines()[-1])
            self.assertEqual(call[-len(FLAGS) :], FLAGS)
            self.assertEqual("--sudo" in call, not recipe.startswith("build"))
            host = {"pc": "nixos-pc", "lp": "nixos-lp", "server": "nixos-server"}.get(
                recipe.rsplit("-", 1)[-1], "nixos-pc"
            )
            self.assertIn(
                f".#nixosConfigurations.{host}.config.system.build.toplevel"
                if recipe.startswith("build") else f".#{host}", call,
            )

        subprocess.run(
            [shutil.which("just"), "--justfile", str(ROOT / "justfile"), "default"],
            cwd=ROOT, env=env, check=True, capture_output=True,
        )

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
            self.assertEqual("--sudo" in call, helper != "nb")


if __name__ == "__main__":
    unittest.main()
