#!/usr/bin/env python3
"""Exercise setup only in disposable copies; Nix integration is opt-in."""
import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class SetupTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="my-nixos-setup-test-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name) / "repo"
        tracked = subprocess.check_output(["git", "ls-files", "-z"], cwd=ROOT, text=True).split(
            "\0"
        )
        for name in set(tracked) | {
            "setup.sh",
            "lib/setup.py",
            "templates/host/configuration.nix.in",
            "tests/test_setup.py",
            "tests/test_nixos_command.py",
        }:
            if name and (ROOT / name).is_file():
                target = self.root / name
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(ROOT / name, target)
        self.env = {k: v for k, v in os.environ.items() if k != "MY_NIXOS_PRIVATE"}
        # A scratch store permits real private-flake evaluation without a system daemon.
        self.env.update(
            NIX_REMOTE=f"local?store={self.temp.name}/store&state={self.temp.name}/state&log={self.temp.name}/log",
            XDG_CACHE_HOME=f"{self.temp.name}/cache",
        )
        self.git("init", "-q")
        self.git("add", ".")
        self.git(
            "-c",
            "user.name=Test",
            "-c",
            "user.email=test@example.invalid",
            "commit",
            "-qm",
            "fixture",
        )
        key = Path(self.temp.name) / "key"
        subprocess.run(["ssh-keygen", "-qt", "ed25519", "-N", "", "-f", str(key)], check=True)
        self.key = key.with_suffix(".pub")

    def git(self, *args):
        return subprocess.check_output(["git", "-C", str(self.root), *args], text=True).strip()

    def host_answers(self, **overrides):
        fields = {
            "host": "my-box",
            "kind": "desktop",
            "username": "alice",
            "full_name": 'Alice @hostname@ ${literal} "Example"',
            "git_name": "",
            "git_email": "",
            "timezone": "UTC",
            "locale": "en_US.UTF-8",
            "installation": "new",
            "system_state": "26.05",
            "home_state": "26.05",
            "firmware": "uefi",
            "boot_path": "/boot",
        }
        fields.update(overrides)
        return list(fields.values())

    def answers(
        self,
        *,
        mode="none",
        private=None,
        auth="ssh",
        password_file=None,
        public_key=None,
        ciphertext=None,
        policy=None,
        accept_ssh="yes",
        confirm="yes",
        cleanup="",
        cleanup_confirm="no",
        fresh="",
        fresh_confirm="no",
        **host,
    ):
        answers = [mode]
        if mode == "external":
            answers.append(str(private))

        answers.extend(self.host_answers(**host))
        answers.append(auth)
        if auth == "password-file":
            answers.append(str(password_file))
        answers.append(str(self.key) if public_key is None else public_key)
        if auth == "ssh":
            answers.append(accept_ssh)

        if mode == "local":
            answers.extend([str(ciphertext), str(policy)])

        answers.extend([confirm, cleanup])
        if cleanup == "yes":
            answers.append(cleanup_confirm)
        answers.append(fresh)
        if fresh == "yes":
            answers.append(fresh_confirm)

        return answers

    def setup(self, answers):
        return subprocess.run(
            [sys.executable, "lib/setup.py"],
            cwd=self.root,
            input="\n".join(answers) + "\n",
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            env=self.env,
        )

    def test_root_launcher_provides_python_through_nix(self):
        original_root = self.root
        self.root = Path(self.temp.name) / "repo with spaces ' \" \\ π # %"
        original_root.rename(self.root)

        tools = Path(self.temp.name) / "bin"
        tools.mkdir()
        log = Path(self.temp.name) / "nix-arguments.json"
        nix = tools / "nix"
        nix.write_text(
            "#!/usr/bin/env python3\n"
            "import json, os, sys\n"
            "from pathlib import Path\n"
            "Path(os.environ['SETUP_TEST_NIX_LOG']).write_text(json.dumps(sys.argv[1:]))\n"
            "command = sys.argv.index('--command')\n"
            "os.execv(sys.executable, [sys.executable, *sys.argv[command + 2:]])\n"
        )
        nix.chmod(0o755)
        environment = dict(
            self.env, PATH=f"{tools}:{os.environ['PATH']}", SETUP_TEST_NIX_LOG=str(log)
        )

        result = subprocess.run(
            ["bash", str(self.root / "setup.sh")],
            cwd=self.temp.name,
            input="\n".join(self.answers()) + "\n",
            text=True,
            capture_output=True,
            env=environment,
        )

        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertTrue(log.exists(), "The root launcher should obtain Python through Nix")
        arguments = json.loads(log.read_text())
        self.assertIn("shell", arguments)
        self.assertIn("--impure", arguments)
        expression = arguments[arguments.index("--expr") + 1]
        self.assertIn("./flake.lock", expression)
        self.assertIn("builtins.fetchTree", expression)
        self.assertIn("pyyaml", expression)
        self.assertEqual(arguments[arguments.index("--command") + 1 :], ["python3", "lib/setup.py"])
        self.assertTrue((self.root / "hosts/my-box/configuration.nix").is_file())

    def encrypted_source(self):
        ciphertext = Path(self.temp.name) / "host.yaml"
        encrypted = "ENC[AES256_GCM,data:Zml4dHVyZQ==,iv:fixture,tag:fixture,type:str]"
        ciphertext.write_text(
            f"""user_password_hash: {encrypted}
sops:
  age:
    - recipient: age1fixture
      enc: |
        -----BEGIN AGE ENCRYPTED FILE-----
        fixture
        -----END AGE ENCRYPTED FILE-----
  mac: {encrypted}
"""
        )
        policy = Path(self.temp.name) / "policy.yaml"
        policy.write_text(
            "creation_rules:\n  - path_regex: secrets/hosts/my-box[.]yaml$\n    age: age1fixture\n"
        )
        return ciphertext, policy

    @unittest.skipUnless(
        importlib.util.find_spec("yaml"),
        "Run with PyYAML (the existing SOPS validator dependency)",
    )
    def test_local_sops(self):
        ciphertext, policy = self.encrypted_source()
        answers = self.answers(
            mode="local",
            auth="sops",
            public_key="",
            ciphertext=ciphertext,
            policy=policy,
        )
        result = self.setup(answers)
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertEqual(
            (self.root / "secrets/hosts/my-box.yaml").read_bytes(),
            ciphertext.read_bytes(),
        )
        self.assertEqual((self.root / ".sops.yaml").read_bytes(), policy.read_bytes())
        config = (self.root / "hosts/my-box/configuration.nix").read_text()
        self.assertIn("neededForUsers = true", config)
        self.assertIn("hashedPasswordFile = config.sops.secrets.user-password.path", config)
        self.assertIn('secretSource = "local"', (self.root / "flake/hosts.nix").read_text())
        self.assertIn(".sops.yaml secrets/hosts/my-box.yaml", result.stdout)
        subprocess.run(
            ["nix-instantiate", "--parse", "hosts/my-box/configuration.nix"],
            cwd=self.root,
            check=True,
            stdout=subprocess.DEVNULL,
        )

    @unittest.skipUnless(
        importlib.util.find_spec("yaml"),
        "Run with PyYAML (the existing SOPS validator dependency)",
    )
    def test_local_plaintext_is_rejected(self):
        ciphertext, policy = self.encrypted_source()
        ciphertext.write_text(
            ciphertext.read_text().replace(
                "user_password_hash: ENC[", "user_password_hash: plaintext ENC["
            )
        )
        result = self.setup(
            self.answers(
                mode="local", auth="sops", public_key="", ciphertext=ciphertext, policy=policy
            )
        )
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertEqual(self.git("status", "--porcelain"), "")

    def private_source(self):
        ciphertext, _ = self.encrypted_source()
        private = Path(self.temp.name) / "private ' \" \\ $NAME # % ? directory"
        private.mkdir()
        shutil.copyfile(ciphertext, private / "host.yaml")
        (private / "flake.nix").write_text(
            """{
  outputs = { self }: {
    secretFiles.my-box = ./host.yaml;
    nixosModules.my-box = { lib, ... }: { time.timeZone = lib.mkForce "UTC"; };
  };
}"""
        )
        return private

    @unittest.skipUnless(
        importlib.util.find_spec("yaml"),
        "Run with PyYAML (the existing SOPS validator dependency)",
    )
    def test_external_private_directory(self):
        private = self.private_source()
        result = self.setup(
            self.answers(mode="external", private=private, auth="sops", public_key="")
        )
        self.assertEqual(result.returncode, 0, result.stdout)
        registration = (self.root / "flake/hosts.nix").read_text()
        self.assertIn('secretSource = "private"', registration)
        self.assertIn("requirePrivate = true", registration)
        self.assertIn(".env", self.git("ls-files", "--others", "--ignored", "--exclude-standard"))
        self.assertNotIn(str(private), self.git("diff"))
        dotenv = subprocess.run(
            [
                "just",
                "--command",
                "python3",
                "-c",
                "import os; print(os.environ['MY_NIXOS_PRIVATE'])",
            ],
            cwd=self.root,
            capture_output=True,
            text=True,
            env=self.env,
        )
        self.assertEqual(dotenv.returncode, 0, dotenv.stderr)
        self.assertEqual(dotenv.stdout.strip(), str(private))

    @unittest.skipUnless(importlib.util.find_spec("yaml"), "Run with PyYAML")
    def test_external_private_git_must_be_clean(self):
        private = self.private_source()
        subprocess.run(["git", "init", "-q", str(private)], check=True)
        dirty = self.setup(["external", str(private)])
        self.assertNotEqual(dirty.returncode, 0, dirty.stdout)
        self.assertEqual(self.git("status", "--porcelain"), "")
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
        result = self.setup(
            self.answers(mode="external", private=private, auth="sops", public_key="")
        )
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertIn("git+file://", result.stdout)
        self.assertEqual(self.git("diff", "--", "flake.lock"), "")

    def test_external_missing_host_and_existing_env(self):
        private = Path(self.temp.name) / "private"
        private.mkdir()
        (private / "flake.nix").write_text(
            "{ outputs = {self}: { secretFiles = {}; nixosModules = {}; }; }"
        )
        result = self.setup(self.answers(mode="external", private=private))
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertEqual(self.git("status", "--porcelain"), "")
        (self.root / ".env").write_text("KEEP=fixture\n")
        conflict = self.setup(["external", str(private)])
        self.assertNotEqual(conflict.returncode, 0, conflict.stdout)
        self.assertEqual((self.root / ".env").read_text(), "KEEP=fixture\n")

    def test_fresh_git_failure_preserves_history(self):
        head = self.git("rev-parse", "HEAD")
        tools = Path(self.temp.name) / "bin"
        tools.mkdir()
        git = tools / "git"
        git.write_text("#!/bin/sh\nexit 1\n")
        git.chmod(0o755)
        self.env["PATH"] = f"{tools}:{os.environ['PATH']}"
        result = self.setup(self.answers(fresh="yes", fresh_confirm="start fresh"))
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertEqual(self.git("rev-parse", "HEAD"), head)
        self.assertFalse((self.root / ".git.setup-backup").exists())

    def test_bios_boot(self):
        answers = self.answers(firmware="bios", boot_path="/dev/disk/by-id/setup-fixture")
        result = self.setup(answers)
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertIn(
            "boot.loader.grub", (self.root / "hosts/my-box/configuration.nix").read_text()
        )

    def test_no_secrets_and_rerun(self):
        result = self.setup(self.answers())
        self.assertEqual(result.returncode, 0, result.stdout)
        host = self.root / "hosts/my-box"
        self.assertFalse((host / "hardware-configuration.nix").exists())
        self.assertEqual(
            (host / "profile.nix").read_bytes(),
            (self.root / "templates/host/profile.nix").read_bytes(),
        )
        config = (host / "configuration.nix").read_text()
        self.assertIn('hashedPassword = "!"', config)
        self.assertIn("wheelNeedsPassword = false", config)
        self.assertIn(r"\${literal}", config)
        self.assertIn("@hostname@", config)
        self.assertIn('secretSource = "none"', (self.root / "flake/hosts.nix").read_text())
        self.assertIn("just build my-box", result.stdout)
        self.assertIn("hardware-configuration.nix", result.stdout)
        subprocess.run(
            ["nix-instantiate", "--parse", "hosts/my-box/configuration.nix"],
            cwd=self.root,
            check=True,
            stdout=subprocess.DEVNULL,
        )
        self.assertEqual(self.git("diff", "--cached"), "")
        before = self.git("status", "--porcelain")
        rerun = self.setup(self.answers())
        self.assertNotEqual(rerun.returncode, 0)
        self.assertEqual(self.git("status", "--porcelain"), before)

    def test_cancellation_and_invalid_names_leave_no_changes(self):
        for answers in (
            [],
            ["none", "../bad"],
            ["none", "pc"],
            ["none", "ok", "server", "root"],
            self.answers(confirm="no"),
        ):
            with self.subTest(answers=answers[:4]):
                result = self.setup(answers)
                self.assertNotEqual(result.returncode, 0, result.stdout)
                self.assertEqual(self.git("status", "--porcelain"), "")

    def test_invalid_settings_and_declined_ssh_auth(self):
        for changes in (
            {"kind": "phone"},
            {"timezone": "/etc/passwd"},
            {"locale": "bad-locale"},
            {"system_state": "27.05"},
            {"boot_path": "relative"},
            {"accept_ssh": "no"},
        ):
            with self.subTest(changes=changes):
                result = self.setup(self.answers(**changes))
                self.assertNotEqual(result.returncode, 0, result.stdout)
                self.assertEqual(self.git("status", "--porcelain"), "")

    def test_write_failure_rolls_back_registration(self):
        hosts = self.root / "hosts"
        hosts.chmod(0o555)
        try:
            result = self.setup(self.answers())
            self.assertNotEqual(result.returncode, 0, result.stdout)
            self.assertEqual(self.git("status", "--porcelain"), "")
        finally:
            hosts.chmod(0o755)

    def test_destructive_choices_require_exact_confirmation(self):
        previous_head = self.git("rev-parse", "HEAD")
        answers = self.answers(cleanup="yes", cleanup_confirm="no", fresh="yes", fresh_confirm="no")
        result = self.setup(answers)
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertTrue((self.root / "hosts/pc/configuration.nix").exists())
        self.assertEqual(self.git("rev-parse", "HEAD"), previous_head)

    def test_cleanup_failure_restores_files_and_registrations(self):
        original = self.root / "hosts/pc"
        original.chmod(0o555)
        answers = self.answers(cleanup="yes", cleanup_confirm="remove original hosts")
        try:
            result = self.setup(answers)
            self.assertNotEqual(result.returncode, 0, result.stdout)
            self.assertTrue((original / "configuration.nix").exists())
            self.assertIn("nixos-pc = mkHost", (self.root / "flake/hosts.nix").read_text())
            self.assertEqual(
                self.git("diff", "--", "hosts/pc", "hosts/laptop", "hosts/server", "justfile"), ""
            )
        finally:
            original.chmod(0o755)

    def test_cleanup_and_fresh_git(self):
        answers = self.answers(
            kind="server",
            cleanup="yes",
            cleanup_confirm="remove original hosts",
            fresh="yes",
            fresh_confirm="start fresh",
        )
        result = self.setup(answers)
        self.assertEqual(result.returncode, 0, result.stdout)
        for name in ("pc", "laptop", "server"):
            self.assertFalse((self.root / "hosts" / name).exists())
        registrations = (self.root / "flake/hosts.nix").read_text()
        self.assertNotIn("nixos-pc = mkHost", registrations)
        self.assertIn('"my-box" = mkHost', registrations)
        self.assertTrue((self.root / "modules").is_dir())
        self.assertTrue((self.root / ".git").is_dir())
        self.assertNotEqual(
            subprocess.run(
                ["git", "rev-parse", "--verify", "--quiet", "HEAD"],
                cwd=self.root,
                capture_output=True,
            ).returncode,
            0,
        )
        self.assertEqual(self.git("remote"), "")
        self.assertEqual(self.git("diff", "--cached"), "")

    def test_reserved_hostname_is_valid_nix(self):
        result = self.setup(self.answers(host="if"))
        self.assertEqual(result.returncode, 0, result.stdout)
        parsed = subprocess.run(
            ["nix-instantiate", "--parse", "flake/hosts.nix"],
            cwd=self.root,
            capture_output=True,
            text=True,
        )
        self.assertEqual(parsed.returncode, 0, parsed.stderr)

    def test_password_file_and_existing_state_versions(self):
        password_file = Path(self.temp.name) / "password-hash"
        password_file.write_text("$6$fixture$not-a-real-password-hash\n")
        password_file.chmod(0o600)
        answers = self.answers(
            kind="laptop",
            installation="existing",
            system_state="23.11",
            home_state="24.05",
            auth="password-file",
            password_file=password_file,
            public_key="",
        )
        result = self.setup(answers)
        self.assertEqual(result.returncode, 0, result.stdout)
        config = (self.root / "hosts/my-box/configuration.nix").read_text()
        self.assertIn('system.stateVersion = "23.11"', config)
        self.assertIn('home.stateVersion = "24.05"', config)
        self.assertIn(f'hashedPasswordFile = "{password_file}"', config)
        self.assertNotIn(password_file.read_text().strip(), config)
        self.assertIn("wheelNeedsPassword = true", config)
        self.assertNotIn("services.openssh", config)

    def test_password_file_must_be_protected(self):
        password_file = Path(self.temp.name) / "password-hash"
        password_file.write_text("fixture")
        password_file.chmod(0o644)
        answers = self.answers(auth="password-file", password_file=password_file, public_key="")
        result = self.setup(answers)
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertEqual(self.git("status", "--porcelain"), "")

    def test_cleanup_declined_and_state_preserved(self):
        state = self.root / "hosts/pc/runtime.db"
        state.write_text("preserve this")
        answers = self.answers(cleanup="yes")
        result = self.setup(answers)
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertEqual(state.read_text(), "preserve this")
        self.assertTrue((self.root / "hosts/pc/configuration.nix").exists())

    def test_missing_sources(self):
        result = self.setup(["external", "/does/not/exist"])
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.git("status", "--porcelain"), "")

    def test_invalid_private_git_is_rejected(self):
        private = self.private_source()
        (private / ".git").write_text("gitdir: /does/not/exist\n")
        result = self.setup(["external", str(private)])
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertIn("Cannot inspect the private Git checkout", result.stdout)
        self.assertEqual(self.git("status", "--porcelain"), "")

    @unittest.skipUnless(
        os.environ.get("MY_NIXOS_SETUP_BUILD_TESTS") == "1",
        "Set MY_NIXOS_SETUP_BUILD_TESTS=1 for full Nix evaluation/build",
    )
    def test_generated_host_build(self):
        environment = dict(self.env)
        environment.pop("NIX_REMOTE")
        result = subprocess.run(
            ["bash", "setup.sh"],
            cwd=self.root,
            input="\n".join(self.answers()) + "\n",
            env=environment,
            text=True,
            capture_output=True,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        (self.root / "hosts/my-box/hardware-configuration.nix").write_text(
            """{
  fileSystems."/" = { device = "/dev/disk/by-label/setup-test-root"; fsType = "ext4"; };
  fileSystems."/boot" = { device = "/dev/disk/by-label/setup-test-esp"; fsType = "vfat"; };
}"""
        )
        self.git("add", "hosts/my-box", "flake/hosts.nix")
        for command in (["just", "check", "--no-build"], ["just", "build", "my-box", "--no-link"]):
            with self.subTest(command=command):
                checked = subprocess.run(
                    command,
                    cwd=self.root,
                    env=environment,
                    text=True,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                )
                self.assertEqual(checked.returncode, 0, checked.stdout)
        for name in ("nixos-pc", "nixos-lp", "nixos-server"):
            guard = subprocess.run(
                [
                    "nix",
                    "eval",
                    "--raw",
                    f".#nixosConfigurations.{name}.config.system.systemBuilderCommands",
                ],
                cwd=self.root,
                env=environment,
                text=True,
                capture_output=True,
            )
            with self.subTest(host=name):
                self.assertEqual(guard.returncode, 0, guard.stderr)
                self.assertIn("existing host requires its private input", guard.stdout)


if __name__ == "__main__":
    unittest.main()
