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
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]


class SetupTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="my-nixos-setup-test-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name) / "repo"
        tracked = subprocess.check_output(
            ["git", "ls-files", "-z"], cwd=ROOT, text=True
        ).split("\0")
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
        subprocess.run(
            ["ssh-keygen", "-qt", "ed25519", "-N", "", "-f", str(key)], check=True
        )
        self.key = key.with_suffix(".pub")

    def git(self, *args):
        return subprocess.check_output(
            ["git", "-C", str(self.root), *args], text=True
        ).strip()

    def host_answers(self, **overrides):
        fields = {
            "host": "my-box",
            "kind": "desktop",
            "username": "alice",
            "full_name": 'Alice @hostname@ ${literal} "Example"',
            "timezone": "UTC",
            "locale": "en_US.UTF-8",
            "git_identity": "no",
        }
        fields.update(overrides)
        return list(fields.values())

    def answers(
        self,
        *,
        mode="none",
        private=None,
        auth="password",
        password_file=None,
        public_key="",
        ciphertext=None,
        policy=None,
        accept_ssh="yes",
        confirm="yes",
        installation="new",
        system_state="26.05",
        home_state="26.05",
        firmware="uefi",
        boot_path="/boot",
        same_machine="yes",
        **host,
    ):
        answers = self.host_answers(**host)
        answers.append("no" if mode == "none" else "yes")
        if mode != "none":
            answers.append(mode)
        if mode == "external":
            answers.append(str(private))
        elif mode == "local":
            answers.extend([str(policy), str(ciphertext)])
        answers.append(installation)
        if installation == "existing":
            answers.extend([system_state, "yes", home_state])
        answers.append(auth)
        if auth == "password-file":
            answers.append(str(password_file))
        if auth in ("password", "ssh"):
            answers.append(accept_ssh)
        if auth != "ssh":
            answers.append("yes" if public_key else "no")
        if auth == "ssh" or public_key:
            answers.append(str(self.key) if public_key is None else public_key)
        answers.extend([same_machine, firmware])
        if firmware != "manual":
            answers.append(boot_path)
        if installation == "existing":
            answers.append("yes")
        answers.extend(["generate", confirm])
        return answers

    def setup(self, answers, *args):
        return subprocess.run(
            [sys.executable, "lib/setup.py", *args],
            cwd=self.root,
            input="\n".join(answers) + "\n",
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            env=self.env,
        )

    def prepare_finish(self):
        result = self.setup(self.answers())
        self.assertEqual(result.returncode, 0, result.stdout)
        self.git("add", "hosts/my-box", "flake/hosts.nix")
        self.git(
            "-c",
            "user.name=Test",
            "-c",
            "user.email=test@example.invalid",
            "commit",
            "-qm",
            "host",
        )
        # Only the destructive-flow tests substitute validation; integration builds are real.
        tools = Path(self.temp.name) / "bin"
        tools.mkdir(exist_ok=True)
        just = tools / "just"
        just.write_text(
            '#!/bin/sh\nprintf "%s\\n" "$*" >> "$SETUP_TEST_CHECK_LOG"\nexit "${SETUP_TEST_CHECK_STATUS:-0}"\n'
        )
        just.chmod(0o755)
        self.env["SETUP_TEST_CHECK_LOG"] = str(Path(self.temp.name) / "checks")
        self.env["PATH"] = f"{tools}:{os.environ['PATH']}"

    def finish(
        self,
        *,
        cleanup="no",
        cleanup_confirm="no",
        fresh="no",
        fresh_confirm="no",
        verified="yes",
    ):
        answers = [verified, cleanup]
        if cleanup == "yes":
            answers.append(cleanup_confirm)
        answers.append(fresh)
        if fresh == "yes":
            answers.append(fresh_confirm)
        return self.setup(answers, "--finish", "my-box")

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
        self.assertTrue(
            log.exists(), "The root launcher should obtain Python through Nix"
        )
        arguments = json.loads(log.read_text())
        self.assertIn("shell", arguments)
        self.assertIn("--impure", arguments)
        expression = arguments[arguments.index("--expr") + 1]
        self.assertIn("./flake.lock", expression)
        self.assertIn("builtins.fetchTree", expression)
        self.assertIn("pyyaml", expression)
        self.assertEqual(
            arguments[arguments.index("--command") + 1 :], ["python3", "lib/setup.py"]
        )
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
        self.assertIn(
            "hashedPasswordFile = config.sops.secrets.user-password.path", config
        )
        self.assertIn(
            'secretSource = "local"', (self.root / "flake/hosts.nix").read_text()
        )
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
                mode="local",
                auth="sops",
                public_key="",
                ciphertext=ciphertext,
                policy=policy,
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
        self.assertIn(
            ".env", self.git("ls-files", "--others", "--ignored", "--exclude-standard")
        )
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
        dirty = self.setup(
            self.host_answers() + ["yes", "external", str(private), ":cancel"]
        )
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
        conflict = self.setup(
            self.host_answers() + ["yes", "external", str(private), ":cancel"]
        )
        self.assertNotEqual(conflict.returncode, 0, conflict.stdout)
        self.assertEqual((self.root / ".env").read_text(), "KEEP=fixture\n")

    def test_fresh_git_failure_preserves_history(self):
        self.prepare_finish()
        head = self.git("rev-parse", "HEAD")
        tools = Path(self.temp.name) / "bin"
        tools.mkdir(exist_ok=True)
        git = tools / "git"
        git.write_text("#!/bin/sh\nexit 1\n")
        git.chmod(0o755)
        self.env["PATH"] = f"{tools}:{os.environ['PATH']}"
        result = self.finish(fresh="yes", fresh_confirm="start fresh")
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertEqual(self.git("rev-parse", "HEAD"), head)
        self.assertFalse((self.root.parent / "repo.git-backup").exists())

    def test_bios_boot(self):
        answers = self.answers(
            firmware="bios", boot_path="/dev/disk/by-id/setup-fixture"
        )
        result = self.setup(answers)
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertIn(
            "boot.loader.grub",
            (self.root / "hosts/my-box/configuration.nix").read_text(),
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
        self.assertIn('initialHashedPassword = "!"', config)
        self.assertIn("wheelNeedsPassword = true", config)
        self.assertIn("users.mutableUsers = true", config)
        self.assertNotIn("services.openssh", config)
        self.assertIn("LOGIN SETUP IS INCOMPLETE", result.stdout)
        self.assertIn("sudo nixos-enter --root /mnt -c 'passwd alice'", result.stdout)
        self.assertNotIn("just switch", result.stdout)
        self.assertIn(r"\${literal}", config)
        self.assertIn("@hostname@", config)
        self.assertIn(
            'secretSource = "none"', (self.root / "flake/hosts.nix").read_text()
        )
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
            ["../bad", ":cancel"],
            ["pc", ":cancel"],
            ["ok", "server", "root", ":cancel"],
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
            {"installation": "existing", "system_state": "27.05"},
            {"boot_path": "relative"},
            {"accept_ssh": "no"},
            {"auth": "ssh", "public_key": None, "accept_ssh": "no"},
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
        self.prepare_finish()
        previous_head = self.git("rev-parse", "HEAD")
        result = self.finish(
            cleanup="yes", cleanup_confirm="no", fresh="yes", fresh_confirm="no"
        )
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertTrue((self.root / "hosts/pc/configuration.nix").exists())
        self.assertEqual(self.git("rev-parse", "HEAD"), previous_head)

    def test_cleanup_failure_restores_files_and_registrations(self):
        self.prepare_finish()
        original = self.root / "hosts/pc"
        original.chmod(0o555)
        try:
            result = self.finish(cleanup="yes", cleanup_confirm="remove original hosts")
            self.assertNotEqual(result.returncode, 0, result.stdout)
            self.assertTrue((original / "configuration.nix").exists())
            self.assertIn(
                "nixos-pc = mkHost", (self.root / "flake/hosts.nix").read_text()
            )
            self.assertEqual(
                self.git(
                    "diff", "--", "hosts/pc", "hosts/laptop", "hosts/server", "justfile"
                ),
                "",
            )
        finally:
            original.chmod(0o755)

    def test_cleanup_and_fresh_git(self):
        self.prepare_finish()
        result = self.finish(
            cleanup="yes",
            cleanup_confirm="remove original hosts",
            fresh="yes",
            fresh_confirm="start fresh",
        )
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
        backup = self.root.parent / "repo.git-backup"
        self.assertTrue((backup / "HEAD").is_file())
        self.assertIn(str(backup), result.stdout)
        history = subprocess.check_output(
            ["git", f"--git-dir={backup}", "log", "-1", "--format=%s"], text=True
        )
        self.assertEqual(history.strip(), "host")
        subprocess.run(
            [
                "git",
                f"--git-dir={backup}",
                "--work-tree=.",
                "restore",
                "--source=HEAD",
                "--worktree",
                "--",
                "hosts/pc",
                "hosts/laptop",
                "hosts/server",
                "flake/hosts.nix",
                "justfile",
            ],
            cwd=self.root,
            check=True,
        )
        self.assertTrue((self.root / "hosts/pc/configuration.nix").is_file())

    def test_beginner_defaults_and_help(self):
        self.env["USER"] = "alice"
        self.env.pop("SUDO_USER", None)
        result = self.setup(
            [
                "?",
                "",
                "",
                "",
                "",
                "",
                "",
                "",
                "",
                "new",
                "",
                "yes",
                "",
                "",
                "uefi",
                "",
                "generate",
                "yes",
            ]
        )
        self.assertEqual(result.returncode, 0, result.stdout)
        config = (self.root / "hosts/my-nixos/configuration.nix").read_text()
        self.assertIn('name = lib.mkDefault "alice"', config)
        self.assertIn("networkmanager.enable = true", config)
        self.assertNotIn("SOPS", result.stdout)
        self.assertNotIn("hash file", result.stdout)
        self.assertNotIn("Remove original", result.stdout)
        for step in range(1, 6):
            self.assertIn(f"Step {step}/5", result.stdout)

    def test_server_has_password_login_without_forced_ssh(self):
        result = self.setup(self.answers(kind="server"))
        self.assertEqual(result.returncode, 0, result.stdout)
        config = (self.root / "hosts/my-box/configuration.nix").read_text()
        self.assertIn("networking.useDHCP = lib.mkDefault true", config)
        self.assertNotIn("networkmanager", config)
        self.assertNotIn("services.openssh", config)
        self.assertIn("wheelNeedsPassword = true", config)

    def test_ssh_only_requires_key_and_explicit_consent(self):
        result = self.setup(self.answers(auth="ssh", public_key=None))
        self.assertEqual(result.returncode, 0, result.stdout)
        config = (self.root / "hosts/my-box/configuration.nix").read_text()
        self.assertIn('hashedPassword = "!"', config)
        self.assertIn("mutableUsers = false", config)
        self.assertIn("wheelNeedsPassword = false", config)
        self.assertIn("PasswordAuthentication = false", config)
        self.assertIn("openFirewall = true", config)

    def test_ssh_key_validation_retries(self):
        invalid = Path(self.temp.name) / "invalid.pub"
        invalid.write_text("not an OpenSSH public key\n")
        answers = self.answers(auth="ssh", public_key=None)
        index = answers.index(str(self.key))
        answers[index:index] = ["/does/not/exist", str(invalid)]
        result = self.setup(answers)
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertEqual(result.stdout.count("Please try again:"), 2)

    def test_existing_password_and_manual_boot_review(self):
        answers = self.answers(
            installation="existing",
            system_state="23.11",
            home_state="24.05",
            firmware="manual",
        )
        result = self.setup(answers)
        self.assertEqual(result.returncode, 0, result.stdout)
        config = (self.root / "hosts/my-box/configuration.nix").read_text()
        self.assertIn('system.stateVersion = "23.11"', config)
        self.assertIn('home.stateVersion = "24.05"', config)
        self.assertNotIn("boot.loader.systemd-boot.enable", config)
        self.assertIn("REQUIRED before building", config)
        self.assertIn("sudo passwd alice", result.stdout)
        self.assertIn("just switch my-box", result.stdout)
        self.assertNotIn("sudo nixos-install", result.stdout)

    def test_existing_without_previous_home_manager(self):
        answers = self.answers(installation="existing", system_state="24.11")
        index = answers.index("24.11")
        answers[index + 1 : index + 3] = ["no"]
        result = self.setup(answers)
        self.assertEqual(result.returncode, 0, result.stdout)
        config = (self.root / "hosts/my-box/configuration.nix").read_text()
        self.assertIn('system.stateVersion = "24.11"', config)
        self.assertIn('home.stateVersion = "26.05"', config)

    def test_invalid_answers_retry_in_place(self):
        answers = self.answers()
        answers[:1] = ["../bad", "pc", "my-box"]
        answers[answers.index("alice") : answers.index("alice")] = ["root", "Alice"]
        answers[answers.index("UTC") : answers.index("UTC")] = ["/etc/passwd"]
        answers[answers.index("/boot") : answers.index("/boot")] = [
            "/../boot",
            "relative",
        ]
        result = self.setup(answers)
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertGreaterEqual(result.stdout.count("Please try again:"), 7)
        self.assertEqual(result.stdout.count("Step 1/5"), 1)

    def test_missing_source_can_be_corrected(self):
        private = self.private_source()
        answers = self.answers(mode="external", private=private)
        answers.insert(answers.index(str(private)), "/does/not/exist")
        result = self.setup(answers)
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertIn("Please try again:", result.stdout)

    def test_back_changes_previous_answer_without_restarting(self):
        answers = self.answers()
        answers[3:3] = [":back", "bob"]
        result = self.setup(answers)
        self.assertEqual(result.returncode, 0, result.stdout)
        config = (self.root / "hosts/my-box/configuration.nix").read_text()
        self.assertIn('name = lib.mkDefault "bob"', config)
        self.assertEqual(result.stdout.count("Hostname ["), 1)
        self.assertIn("'passwd bob'", result.stdout)

    def test_review_can_edit_a_stage(self):
        answers = (
            self.answers()[:-2]
            + ["edit", "1"]
            + self.answers(host="changed", kind="server")
        )
        result = self.setup(answers)
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertFalse((self.root / "hosts/my-box").exists())
        self.assertTrue((self.root / "hosts/changed/profile.nix").is_file())
        self.assertNotIn(
            '"my-box" = mkHost', (self.root / "flake/hosts.nix").read_text()
        )

    def test_cancel_at_each_stage_never_writes(self):
        answers = self.answers()
        for offset in (0, 2, 7, 8, len(answers) - 2, len(answers) - 1):
            with self.subTest(offset=offset):
                result = self.setup(answers[:offset] + [":cancel"])
                self.assertNotEqual(result.returncode, 0, result.stdout)
                self.assertEqual(self.git("status", "--porcelain"), "")

    def test_no_efi_guess_when_target_is_elsewhere(self):
        answers = self.answers(same_machine="no", firmware="manual")
        result = self.setup(answers)
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertIn("Boot setup (manual/uefi/bios) [manual]", result.stdout)

    def test_existing_confirmation_is_required(self):
        answers = self.answers(installation="existing")
        # Decline the additional confirmation immediately before review.
        answers[-3:] = ["no", ":cancel"]
        result = self.setup(answers)
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertEqual(self.git("status", "--porcelain"), "")

    def test_symlinked_destination_is_not_written(self):
        outside = Path(self.temp.name) / "outside"
        outside.mkdir()
        (self.root / "hosts").rename(self.root / "original-hosts")
        (self.root / "hosts").symlink_to(outside, target_is_directory=True)
        result = self.setup(self.answers())
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertIn("symlinked directories", result.stdout)
        self.assertEqual(list(outside.iterdir()), [])

    def test_finish_build_failure_and_unverified_login_block_cleanup(self):
        self.prepare_finish()
        head = self.git("rev-parse", "HEAD")
        self.env["SETUP_TEST_CHECK_STATUS"] = "1"
        result = self.finish(
            cleanup="yes",
            cleanup_confirm="remove original hosts",
            fresh="yes",
            fresh_confirm="start fresh",
        )
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertNotIn("Remove original", result.stdout)
        self.assertEqual(self.git("rev-parse", "HEAD"), head)
        self.env["SETUP_TEST_CHECK_STATUS"] = "0"
        result = self.setup(["no", ":cancel"], "--finish", "my-box")
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertEqual(self.git("status", "--porcelain"), "")
        self.assertTrue((self.root / "hosts/pc/configuration.nix").is_file())

    def test_cleanup_preserves_modified_sources(self):
        self.prepare_finish()
        path = self.root / "hosts/pc/configuration.nix"
        path.write_text(path.read_text() + "\n# user change\n")
        result = self.finish(cleanup="yes", cleanup_confirm="remove original hosts")
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertIn("# user change", path.read_text())
        self.assertIn("Commit or preserve", result.stdout)

    def test_finish_requires_exact_host_and_git_backups_are_preserved(self):
        self.prepare_finish()
        unknown = self.setup([], "--finish", "../pc")
        self.assertNotEqual(unknown.returncode, 0, unknown.stdout)
        backup = self.root.parent / "repo.git-backup"
        backup.mkdir()
        (backup / "keep").write_text("previous backup")
        head = self.git("rev-parse", "HEAD")
        result = self.finish(fresh="yes", fresh_confirm="start fresh")
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertEqual(self.git("rev-parse", "HEAD"), head)
        self.assertEqual((backup / "keep").read_text(), "previous backup")

    def test_fresh_git_does_not_require_removing_hosts(self):
        self.prepare_finish()
        result = self.finish(fresh="yes", fresh_confirm="start fresh")
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertTrue((self.root / "hosts/pc/configuration.nix").is_file())
        self.assertTrue((self.root.parent / "repo.git-backup/HEAD").is_file())
        self.assertEqual(
            Path(self.env["SETUP_TEST_CHECK_LOG"]).read_text().splitlines(),
            ["check --no-build", "build my-box --no-link"],
        )

    def test_cleanup_directory_failure_rolls_back_everything(self):
        spec = importlib.util.spec_from_file_location(
            "setup_test", self.root / "lib/setup.py"
        )
        setup = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(setup)
        folder = Path(self.temp.name) / "transaction"
        folder.mkdir()
        path = folder / "configuration.nix"
        path.write_text("preserve")
        with patch.object(
            Path, "rmdir", side_effect=OSError("injected directory removal failure")
        ):
            with self.assertRaises(OSError):
                setup.write_files({path: None}, remove_directories=[folder])
        self.assertEqual(path.read_text(), "preserve")

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
            kind="desktop",
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
        answers = self.answers(
            auth="password-file", password_file=password_file, public_key=""
        )
        result = self.setup(answers)
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertEqual(self.git("status", "--porcelain"), "")

    def test_cleanup_declined_and_state_preserved(self):
        self.prepare_finish()
        state = self.root / "hosts/pc/runtime.db"
        state.write_text("preserve this")
        result = self.finish(cleanup="yes")
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertEqual(state.read_text(), "preserve this")
        self.assertTrue((self.root / "hosts/pc/configuration.nix").exists())

    def test_missing_sources(self):
        result = self.setup(
            self.host_answers() + ["yes", "external", "/does/not/exist", ":cancel"]
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.git("status", "--porcelain"), "")

    def test_invalid_private_git_is_rejected(self):
        private = self.private_source()
        (private / ".git").write_text("gitdir: /does/not/exist\n")
        result = self.setup(
            self.host_answers() + ["yes", "external", str(private), ":cancel"]
        )
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
        server = self.setup(self.answers(host="my-server", kind="server"))
        self.assertEqual(server.returncode, 0, server.stdout)
        for host in ("my-box", "my-server"):
            (self.root / f"hosts/{host}/hardware-configuration.nix").write_text(
                """{
  fileSystems."/" = { device = "/dev/disk/by-label/setup-test-root"; fsType = "ext4"; };
  fileSystems."/boot" = { device = "/dev/disk/by-label/setup-test-esp"; fsType = "vfat"; };
}"""
            )
        self.git("add", "hosts/my-box", "hosts/my-server", "flake/hosts.nix")
        for command in (
            ["just", "check", "--no-build"],
            ["just", "build", "my-box", "--no-link"],
            ["just", "build", "my-server", "--no-link"],
        ):
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
        for host, network_manager in (("my-box", True), ("my-server", False)):
            expression = f'''let c = (builtins.getFlake (toString ./.)).nixosConfigurations."{host}".config;
                in {{
                  mutable = c.users.mutableUsers;
                  initial = c.users.users.alice.initialHashedPassword;
                  password = c.users.users.alice.hashedPassword;
                  passwordFile = c.users.users.alice.hashedPasswordFile;
                  sudo = c.security.sudo.wheelNeedsPassword;
                  networkManager = c.networking.networkmanager.enable;
                }}'''
            evaluated = subprocess.run(
                ["nix", "eval", "--impure", "--json", "--expr", expression],
                cwd=self.root,
                env=environment,
                text=True,
                capture_output=True,
            )
            self.assertEqual(evaluated.returncode, 0, evaluated.stderr)
            self.assertEqual(
                json.loads(evaluated.stdout),
                dict(
                    mutable=True,
                    initial="!",
                    password=None,
                    passwordFile=None,
                    sudo=True,
                    networkManager=network_manager,
                ),
            )
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
