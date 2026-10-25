#!/usr/bin/env python3
"""One-time host setup. Never activate or install a system."""

import json
import os
from pathlib import Path
import re
import shlex
import shutil
import subprocess
import sys
from urllib.parse import quote

ROOT = Path(__file__).resolve().parents[1]


def fail(message):
    raise ValueError(message)


class Back(Exception):
    pass


class Wizard:
    """Replay accepted answers when navigating back; never persist wizard state."""

    def __init__(self):
        self.answers = []
        self.cursor = 0
        self.steps = {}

    def step(self, number, title):
        self.steps[number] = self.cursor
        if self.cursor == len(self.answers):
            print(f"\nStep {number}/5 — {title}")

    def ask(self, label, default="", validate=str, help=""):
        if self.cursor < len(self.answers):
            answer = self.answers[self.cursor]
            self.cursor += 1
            return answer
        while True:
            prompt = f"{label} [{default}]" if default else label
            value = input(f"{prompt}: ").strip()
            if value == ":cancel":
                raise KeyboardInterrupt
            if value == ":back":
                if self.cursor:
                    self.answers = self.answers[: self.cursor - 1]
                    raise Back
                print("You are at the first question.")
                continue
            if value == "?":
                print(
                    help
                    or "Enter an answer, or press Enter to accept the shown default."
                )
                continue
            try:
                value = value or default
                if any(ord(c) < 32 or ord(c) == 127 for c in value):
                    fail("Control characters are not allowed.")
                answer = validate(value)
            except (ValueError, OSError, subprocess.CalledProcessError) as error:
                print(f"Please try again: {error}")
                continue
            self.answers.append(answer)
            self.cursor += 1
            return answer

    def choice(self, label, values, default, **kwargs):
        def validate(value):
            if value not in values:
                fail(f"Choose one of: {', '.join(values)}.")
            return value

        return self.ask(f"{label} ({'/'.join(values)})", default, validate, **kwargs)


def checked(value, pattern, message):
    if not re.fullmatch(pattern, value):
        fail(message)
    return value


def confirm(wizard, label, help=""):
    def validate(value):
        if value != "yes":
            fail(
                "Answer yes to continue, :back to change your answer, or :cancel to leave."
            )
        return value

    return wizard.ask(label + " (yes/no)", "no", validate, help)


def nix_string(value):
    # JSON escaping alone would still allow Nix's ${...} interpolation.
    return json.dumps(value, ensure_ascii=False).replace("${", r"\${")


def command_output(*args):
    return subprocess.check_output(args, cwd=ROOT, text=True).strip()


def source_path(value):
    path = Path(value).expanduser().resolve(strict=True)

    if not path.is_file():
        fail("Expected an existing regular file.")
    return path


def write_files(files, remove_directories=()):
    previous = {path: path.read_bytes() if path.exists() else None for path in files}
    changed = []
    directories = []

    try:
        for path, content in files.items():
            if not path.parent.exists():
                path.parent.mkdir()
                directories.append(path.parent)

            changed.append(path)
            if content is None:
                path.unlink()
            else:
                path.write_bytes(content)
        for directory in remove_directories:
            directory.rmdir()
    except BaseException:
        # Roll back earlier writes on errors and Ctrl-C, without touching the Git index.
        for directory in remove_directories:
            directory.mkdir(exist_ok=True)
        for path in reversed(changed):
            if previous[path] is None:
                path.unlink(missing_ok=True)
            elif not path.exists() or path.read_bytes() != previous[path]:
                path.write_bytes(previous[path])
        for directory in reversed(directories):
            directory.rmdir()
        raise


def check_ciphertext(ciphertext, policy, host):
    subprocess.run(
        [
            sys.executable,
            str(ROOT / "lib/check-sops-source.py"),
            str(ciphertext),
            str(policy),
            host,
        ],
        check=True,
    )


def private_directory(value):
    if not value:
        fail("Enter the existing private directory path.")
    private = Path(value).expanduser().resolve(strict=True)
    if not private.is_dir() or not (private / "flake.nix").is_file():
        fail("Private source must be a directory containing flake.nix.")
    if any(ord(c) < 32 or ord(c) == 127 for c in str(private)):
        fail("Control characters are not allowed in paths.")
    if private == ROOT or ROOT in private.parents or private in ROOT.parents:
        fail("Keep the external private source outside this public repository.")
    if (ROOT / ".env").exists() or (ROOT / ".env").is_symlink():
        fail(
            "An existing .env will not be overwritten; preserve it and configure the private input manually."
        )
    private_ref = "path:" + quote(str(private), safe="/")
    git_root = subprocess.run(
        ["git", "-C", str(private), "rev-parse", "--show-toplevel"],
        capture_output=True,
        text=True,
    )
    if git_root.returncode and (
        (private / ".git").exists() or (private / ".git").is_symlink()
    ):
        fail(
            "Cannot inspect the private Git checkout; refusing an unfiltered directory import."
        )
    if git_root.returncode == 0:
        if Path(git_root.stdout.strip()).resolve() != private:
            fail("Select the private Git checkout root, not a subdirectory.")
        if command_output("git", "-C", str(private), "status", "--porcelain"):
            fail("Private Git checkout must be clean and committed before setup.")
        revision = command_output("git", "-C", str(private), "rev-parse", "HEAD")
        private_ref = f"git+file://{quote(str(private), safe='/')}?rev={revision}"
    return private, private_ref


def private_files(mode, host, private=None, private_ref=None, value="", policy_path=""):
    files = {}
    ciphertext = None
    secret_source = {"none": "none", "local": "local", "external": "private"}[mode]
    if mode == "local":
        ciphertext = source_path(value)
        policy_dest = ROOT / ".sops.yaml"
        if policy_dest.is_symlink():
            fail("The local recipient policy must not be a symlink.")
        policy = policy_dest if policy_dest.is_file() else source_path(policy_path)
        check_ciphertext(ciphertext, policy, host)
        destination = ROOT / f"secrets/hosts/{host}.yaml"
        if ciphertext != destination:
            if destination.exists() or destination.is_symlink():
                fail("The local ciphertext destination already exists.")
            files[destination] = ciphertext.read_bytes()
        if policy != policy_dest:
            files[policy_dest] = policy.read_bytes()
    elif mode == "external":
        expression = f"""
          let
            root = builtins.toPath {nix_string(str(ROOT))};
            selected = import (root + "/lib/secret-source.nix") {{
              inherit root;
              private = builtins.getFlake {nix_string(private_ref)};
              host = {nix_string(host)};
              source = "private";
            }};
          in
            if selected.file == null then
              throw "Private source must export secretFiles.{host}"
            else
              toString selected.file
        """
        ciphertext = command_output(
            "nix",
            "--extra-experimental-features",
            "nix-command flakes",
            "eval",
            "--impure",
            "--raw",
            "--expr",
            expression,
        )
        check_ciphertext(ciphertext, "-", host)
        env_path = json.dumps(str(private), ensure_ascii=False).replace("$", r"\$")
        files[ROOT / ".env"] = f"MY_NIXOS_PRIVATE={env_path}\n".encode()

    return files, ciphertext, secret_source


def host_files(a, files, secret_source, hosts_text):
    host = a["host"]
    host_dir = ROOT / "hosts" / host
    registration = ROOT / "flake/hosts.nix"
    auth = a["auth"]
    password_file = a["password_file"]
    ssh_key = a["ssh_key"]
    keys = a["keys"]
    git_name = a["git_name"]
    git_email = a["git_email"]
    boot = a["boot"]
    zone = a["zone"]
    locale = a["locale"]
    system_state = a["system_state"]
    user = a["user"]
    full_name = a["full_name"]
    home_state = a["home_state"]
    mode = a["mode"]
    kind = a["kind"]
    ssh = ""
    if ssh_key:
        ssh = """  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };"""

    sops = ""
    if auth == "sops":
        password = "hashedPasswordFile = config.sops.secrets.user-password.path"
        sops = """  sops.secrets.user-password = {
    sopsFile = secretFile;
    key = "user_password_hash";
    neededForUsers = true;
  };"""
    elif auth == "password":
        password = 'initialHashedPassword = "!"'
    elif password_file:
        password = f"hashedPasswordFile = {nix_string(str(password_file))}"
    else:
        password = 'hashedPassword = "!"'

    git_identity = []
    if git_name:
        git_identity.append(f"    git.userName = {nix_string(git_name)};")
    if git_email:
        git_identity.append(f"    git.userEmail = {nix_string(git_email)};")

    configuration_values = {
        "module_arguments": (
            "config, lib, secretFile, ..." if auth == "sops" else "config, lib, ..."
        ),
        "boot": boot,
        "networking": (
            "  networking.networkmanager.enable = true;"
            if kind == "desktop"
            else "  networking.useDHCP = lib.mkDefault true;"
        ),
        "groups": '[ "wheel" "networkmanager" ]'
        if kind == "desktop"
        else '[ "wheel" ]',
        "mutable_users": "true" if auth == "password" else "false",
        "auth_comment": (
            "  # Existing passwords and passwd changes survive rebuilds; new accounts start locked."
            if auth == "password"
            else "  # Account authentication is managed declaratively."
        ),
        "hostname": nix_string(host),
        "timezone": nix_string(zone),
        "locale": nix_string(locale),
        "system_state": nix_string(system_state),
        "username": nix_string(user),
        "full_name": nix_string(full_name),
        "authorized_keys": keys,
        "home_state": nix_string(home_state),
        "git_identity": "\n".join(git_identity),
        "password": password,
        "sudo_password": "false" if auth == "ssh" else "true",
        "sops": sops,
        "ssh": ssh,
    }
    template = (ROOT / "templates/host/configuration.nix.in").read_text()
    # Substitute once so user values containing @markers@ stay literal.
    config = re.sub(r"@(\w+)@", lambda match: configuration_values[match[1]], template)

    private_guard = "      requirePrivate = true;\n" if mode == "external" else ""
    entry = f"""    "{host}" = mkHost {{
      hostModule = ../hosts/{host}/configuration.nix;
      host = "{host}";
      secretSource = "{secret_source}";
      profile = moduleProfiles.all;
{private_guard}    }};

"""
    anchor = "  flake.nixosConfigurations = {\n"
    if hosts_text.count(anchor) != 1:
        fail("Host registration layout has changed; refusing to edit it.")
    files[registration] = hosts_text.replace(anchor, anchor + entry).encode()
    files[host_dir / "configuration.nix"] = config.encode()
    files[host_dir / "profile.nix"] = (ROOT / "templates/host/profile.nix").read_bytes()

    return files


def finish(host):
    checked(host, r"[a-z][a-z0-9-]{0,61}[a-z0-9]|[a-z]", "Expected a hostname.")
    registration = ROOT / "flake/hosts.nix"
    if not (ROOT / "hosts" / host / "configuration.nix").is_file() or not re.search(
        rf'^    "{re.escape(host)}" = mkHost \{{$', registration.read_text(), re.M
    ):
        fail("Choose a generated host registered in flake/hosts.nix.")
    if (
        registration.is_symlink()
        or registration.parent.is_symlink()
        or (ROOT / "justfile").is_symlink()
    ):
        fail("Refusing cleanup through symlinked configuration files.")
    print(
        "Optional finishing step. First, check and build the new host without activating it."
    )
    subprocess.run(["just", "check", "--no-build"], cwd=ROOT, check=True)
    subprocess.run(["just", "build", host, "--no-link"], cwd=ROOT, check=True)
    print(
        "Build passed. Boot and login must also be verified on the target before cleanup."
    )
    wizard = Wizard()
    confirm(
        wizard, "Have you successfully booted, logged in and used sudo on the new host"
    )
    cleaned = False
    fresh = False
    if (
        wizard.choice(
            "Remove original PC, laptop and server hosts", ("yes", "no"), "no"
        )
        == "yes"
    ):
        removed = []
        new_registration = registration.read_text()
        for name, output in (
            ("pc", "nixos-pc"),
            ("laptop", "nixos-lp"),
            ("server", "nixos-server"),
        ):
            if name == host:
                fail("The newly generated host is never eligible for cleanup.")
            directory = ROOT / "hosts" / name
            if directory.is_symlink():
                fail("Refusing cleanup of a symlinked original host.")
            if directory.exists():
                for path in directory.iterdir():
                    if (
                        path.name
                        not in (
                            "configuration.nix",
                            "profile.nix",
                            "secrets.nix",
                            "hardware-configuration.nix",
                        )
                        or not path.is_file()
                        or path.is_symlink()
                    ):
                        fail(
                            "Original host contains additional state; review it manually before cleanup."
                        )
                    removed.append(path)
            new_registration, count = re.subn(
                rf"^    {output} = mkHost \{{\n.*?^    \}};\n\n?",
                "",
                new_registration,
                flags=re.M | re.S,
            )
            if count != 1:
                fail(
                    "Original host registrations have changed; review cleanup manually."
                )
        justfile = ROOT / "justfile"
        recipes = justfile.read_text().replace(
            'host := "nixos-pc"', f'host := "{host}"'
        )
        alias_pattern = r"\n(?:build|dry|switch|boot)-(?:pc|lp|server) [^\n]*\n(?:[ \t]+[^\n]*\n|\n)*"
        aliases = re.findall(alias_pattern, recipes)
        recipes = re.sub(
            alias_pattern,
            "",
            recipes,
        )
        print(
            "Remove exactly:\n"
            + "\n".join(f"  {p.relative_to(ROOT)}" for p in sorted(removed))
        )
        print(
            "Remove the now-empty hosts/pc, hosts/laptop and hosts/server directories;\n"
            "remove flake registrations nixos-pc, nixos-lp and nixos-server;\n"
            f"set the default just host to {host}. Shared modules, secrets and workspace presets stay."
        )
        print(
            "Remove justfile recipes: "
            + ", ".join(alias.strip().split()[0] for alias in aliases)
        )
        if (
            wizard.ask("Type 'remove original hosts' to confirm")
            == "remove original hosts"
        ):
            if command_output(
                "git",
                "status",
                "--porcelain",
                "--",
                "hosts/pc",
                "hosts/laptop",
                "hosts/server",
                "flake/hosts.nix",
                "justfile",
            ):
                fail(
                    "Commit or preserve changes to cleanup targets before removing original hosts."
                )
            subprocess.run(
                [
                    "git",
                    "ls-files",
                    "--error-unmatch",
                    "--",
                    *[str(p.relative_to(ROOT)) for p in removed],
                ],
                cwd=ROOT,
                check=True,
                stdout=subprocess.DEVNULL,
            )
            write_files(
                {
                    registration: new_registration.encode(),
                    justfile: recipes.encode(),
                    **{path: None for path in removed},
                },
                remove_directories=[
                    ROOT / "hosts" / name
                    for name in ("pc", "laptop", "server")
                    if (ROOT / "hosts" / name).exists()
                ],
            )
            cleaned = True
            print(
                "Host cleanup completed. Before committing, recover with: git restore -- hosts/pc hosts/laptop hosts/server flake/hosts.nix justfile"
            )

    if (
        wizard.choice(
            "Start fresh Git history (keep a recovery backup)",
            ("yes", "no"),
            "no",
        )
        == "yes"
    ):
        git_dir = ROOT / ".git"
        if not git_dir.is_dir() or git_dir.is_symlink():
            fail(
                "Fresh Git initialization requires a normal .git directory, not a worktree or symlink."
            )
        backup = ROOT.parent / f"{ROOT.name}.git-backup"
        if backup.exists() or backup.is_symlink() or (git_dir / "worktrees").exists():
            fail(
                "Review existing Git backups or linked worktrees manually before discarding history."
            )
        if any(
            os.environ.get(name)
            for name in ("GIT_DIR", "GIT_WORK_TREE", "GIT_INDEX_FILE", "GIT_COMMON_DIR")
        ):
            fail(
                "Unset Git directory/index environment overrides before fresh initialization."
            )
        print(
            f"Move exactly: {git_dir} to {backup}\nThe new repository starts without history, branches, remotes, hooks or Git configuration.\n"
            "Working files stay. Nothing will be staged, committed or published."
        )
        if wizard.ask("Type 'start fresh' to confirm") == "start fresh":
            try:
                git_dir.rename(backup)
                subprocess.run(["git", "init", "-b", "main"], cwd=ROOT, check=True)
            except BaseException:
                if backup.exists():
                    if git_dir.exists():
                        shutil.rmtree(git_dir)
                    backup.rename(git_dir)
                raise
            print(
                f"Git recovery backup kept at {backup}. To undo: move the new .git aside and move this backup to .git."
            )
            fresh = True

    if cleaned:
        recovery_git = (
            f"git --git-dir={shlex.quote(str(backup))} --work-tree=."
            if fresh
            else "git"
        )
        print(
            f"Original hosts removed. Recovery: {recovery_git} restore --source=HEAD --worktree -- hosts/pc hosts/laptop hosts/server flake/hosts.nix justfile"
        )
    if fresh:
        print(
            "Fresh Git repository created. Review files and .gitignore before staging anything."
        )


def password_path(value):
    path = source_path(value)
    info = path.stat()
    if (
        ROOT in path.parents
        or Path("/nix/store") in path.parents
        or info.st_mode & 0o077
        or info.st_uid not in (0, os.getuid())
        or not info.st_size
    ):
        fail(
            "Use a nonempty, owner-only runtime hash file outside this repository and /nix/store."
        )
    return path


def public_key(value):
    if not shutil.which("ssh-keygen"):
        fail("ssh-keygen is required to validate the public key.")
    path = source_path(value)
    if path.stat().st_size > 16384:
        fail("Expected one SSH public key, not a private key or large file.")
    with path.open() as key_file:
        prefix = key_file.read(20)
    if not re.match(r"(?:ssh-|ecdsa-|sk-)", prefix):
        fail("Expected an OpenSSH public key file; private keys are never accepted.")
    key = path.read_text().strip()
    if "\n" in key or not re.fullmatch(
        r"(?:ssh-|ecdsa-|sk-)[A-Za-z0-9@._+-]+ [A-Za-z0-9+/=]+(?: [^\r\n]*)?", key
    ):
        fail("Expected one plain OpenSSH public key without authorized_keys options.")
    subprocess.run(
        ["ssh-keygen", "-l", "-f", str(path)],
        check=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    return f"[ {nix_string(key)} ]"


def collect(w):
    a = {}
    w.step(1, "Machine")

    def hostname(value):
        checked(
            value,
            r"[a-z][a-z0-9-]{0,61}[a-z0-9]|[a-z]",
            "Use 1–63 lowercase letters, digits or hyphens, starting with a letter.",
        )
        directory = ROOT / "hosts" / value
        if (
            directory.exists()
            or directory.is_symlink()
            or re.search(
                rf'^\s*"?{re.escape(value)}"?\s*=',
                (ROOT / "flake/hosts.nix").read_text(),
                re.M,
            )
        ):
            fail(
                "That host already exists. Choose another name; setup never overwrites hosts."
            )
        return value

    a["host"] = w.ask("Hostname", "my-nixos", hostname)
    if w.cursor == len(w.answers):
        print(
            "Desktop/laptop: NetworkManager for Wi-Fi and wired connections. Server: basic wired DHCP."
        )
    a["kind"] = w.choice(
        "Machine type",
        ("desktop", "server"),
        "desktop",
        help=(
            "desktop: desktop or laptop, with NetworkManager for Wi-Fi and wired connections. "
            "server: basic wired DHCP. Both start with applications disabled; edit profile.nix later."
        ),
    )

    w.step(2, "User")

    def username(value):
        checked(
            value,
            r"[a-z_][a-z0-9_-]{0,30}",
            "Use lowercase letters, digits, underscores or hyphens; start with a letter or underscore.",
        )
        if value in (
            "root",
            "nobody",
            "nixbld",
            "daemon",
            "bin",
            "sys",
            "sync",
            "mail",
            "sshd",
        ):
            fail("Choose a personal login name, not a system account.")
        return value

    login = os.environ.get("SUDO_USER") or os.environ.get("USER", "user")
    if login in ("root", "nixos") or not re.fullmatch(r"[a-z_][a-z0-9_-]{0,30}", login):
        login = "user"
    a["user"] = w.ask(
        "Username (use your current login name on an existing installation)",
        login,
        username,
    )
    a["full_name"] = w.ask("Full name (optional)")

    def timezone(value):
        checked(
            value, r"[A-Za-z0-9_+/-]+", "Use a timezone such as UTC or Europe/Berlin."
        )
        if (
            value.startswith("/")
            or ".." in value.split("/")
            or not any(
                (Path(base) / value).is_file()
                for base in ("/usr/share/zoneinfo", "/etc/zoneinfo")
            )
        ):
            fail("Timezone not found. Try UTC or Europe/Berlin; ? shows help.")
        return value

    a["zone"] = w.ask(
        "Timezone",
        "UTC",
        timezone,
        "Use a name from: timedatectl list-timezones (for example Europe/Berlin).",
    )
    a["locale"] = w.ask(
        "Language and region",
        "en_US.UTF-8",
        lambda v: checked(
            v,
            r"[a-z]{2,3}_[A-Z]{2}\.UTF-8",
            "Use a UTF-8 locale such as en_US.UTF-8 or de_DE.UTF-8.",
        ),
    )
    a["git_name"] = a["git_email"] = ""
    if w.choice("Set a Git author identity (optional)", ("yes", "no"), "no") == "yes":
        a["git_name"] = w.ask("Git author name", a["full_name"] or a["user"])
        a["git_email"] = w.ask(
            "Git author email",
            validate=lambda v: checked(
                v,
                r"[^\s@]+@[^\s@]+",
                "Enter an email address such as name@example.com.",
            ),
        )

    w.step(3, "Private configuration")
    a["mode"] = "none"
    a["private_ref"] = None
    files, ciphertext, secret_source = {}, None, "none"
    if (
        w.choice(
            "Do you already have a private NixOS configuration", ("yes", "no"), "no"
        )
        == "yes"
    ):
        if w.cursor == len(w.answers):
            print(
                "Local: encrypted files copied into this repository. External: an existing private flake directory."
            )
        a["mode"] = w.choice(
            "Private configuration location",
            ("local", "external"),
            "local",
            help=(
                "local: copy an existing encrypted host YAML and recipient policy into this repository. "
                "external: use an existing private flake directory outside this repository. Nothing is cloned."
            ),
        )
        if a["mode"] == "external":

            def external(value):
                private, ref = private_directory(value)
                if a["user"] == "operator":
                    fail(
                        "The private deployment guard requires a personal username instead of operator (:back to change it)."
                    )
                selected = private_files("external", a["host"], private, ref)
                return ref, selected

            print(
                "Use a reviewed private flake with Nix configuration and encrypted files only. Its source enters the Nix store."
            )
            a["private_ref"], selected = w.ask(
                "Existing external private directory", validate=external
            )
            files, ciphertext, secret_source = selected
        else:
            policy = ROOT / ".sops.yaml"
            policy_path = (
                str(policy)
                if policy.exists()
                else w.ask(
                    "Existing SOPS recipient policy file (.sops.yaml)",
                    validate=lambda v: str(source_path(v)),
                )
            )
            files, ciphertext, secret_source = w.ask(
                "Existing SOPS-encrypted host YAML",
                f"secrets/hosts/{a['host']}.yaml",
                lambda v: private_files(
                    "local", a["host"], value=v, policy_path=policy_path
                ),
            )

    w.step(4, "Login and system")
    a["installation"] = w.choice(
        "Target installation",
        ("existing", "new"),
        "existing" if Path("/etc/NIXOS").exists() else "new",
        help=(
            "existing: replace the configuration of an installed NixOS system. "
            "new: install from live media onto a separately prepared target mounted at /mnt. Setup never partitions disks."
        ),
    )
    a["system_state"] = a["home_state"] = "26.05"
    if a["installation"] == "existing":

        def version(value):
            checked(
                value,
                r"\d{2}\.(03|05|09|11)",
                "Enter the original state version, for example 25.11.",
            )
            if not "15.09" <= value <= "26.05":
                fail("Enter the original state version (at most 26.05).")
            return value

        a["system_state"] = w.ask(
            "Original system.stateVersion (required)",
            validate=version,
            help=(
                "Find system.stateVersion in the target's current NixOS configuration, usually /etc/nixos/configuration.nix. "
                "Keep that value; do not substitute today's release."
            ),
        )
        if (
            w.choice(
                "Has this user used Home Manager on the target before",
                ("yes", "no"),
                "no",
            )
            == "yes"
        ):
            a["home_state"] = w.ask(
                "Original home.stateVersion (required)",
                validate=version,
                help="Find home.stateVersion in the existing Home Manager configuration and keep it unchanged.",
            )

    choices = (
        ("password", "password-file", "ssh")
        if a["mode"] == "none"
        else ("password", "sops", "password-file", "ssh")
    )

    def auth(value):
        if value not in choices:
            fail(f"Choose one of: {', '.join(choices)}.")
        if value == "sops" and not re.search(
            r"^user_password_hash: ENC\[AES256_GCM,.+type:str\]$",
            Path(ciphertext).read_text(),
            re.M,
        ):
            fail(
                "This encrypted file needs a user_password_hash string. Use :back to select another source."
            )
        return value

    a["auth"] = w.ask(
        "Login method (" + "/".join(choices) + ")",
        "password",
        auth,
        help=(
            "password: keep an existing password or set one securely with passwd after installation; sudo requires it. "
            "sops: an encrypted, declaratively managed password. password-file: an already provisioned protected runtime hash. "
            "ssh: advanced key-only access, locked local login and passwordless sudo."
        ),
    )
    a["password_file"] = None
    if a["auth"] == "password":
        print(
            "Existing passwords are preserved. New accounts stay LOCKED until you run passwd. Sudo requires a password."
        )
        confirm(
            w,
            "Will you keep a root recovery shell or installer open to set and test the password before logout/reboot",
        )
    elif a["auth"] == "password-file":
        a["password_file"] = w.ask(
            "Protected runtime password-hash file (must also exist on target)",
            validate=password_path,
        )
    elif a["auth"] == "sops":
        print(
            "Provision the matching protected age identity at /var/lib/sops-nix/key.txt on the target before deployment."
        )
    else:
        confirm(
            w,
            "Accept advanced SSH-only access: locked local login and passwordless sudo",
        )
    a["ssh_key"] = a["auth"] == "ssh"
    a["keys"] = "[ ]"
    if a["auth"] != "ssh":
        a["ssh_key"] = (
            w.choice("Enable remote access with an SSH public key", ("yes", "no"), "no")
            == "yes"
        )
    if a["ssh_key"]:
        a["keys"] = w.ask(
            "SSH public key file (required; SSH opens its firewall port)",
            validate=public_key,
        )

    a["same_machine"] = (
        w.choice("Are you running setup on the target machine", ("yes", "no"), "yes")
        == "yes"
    )
    detected = (
        "uefi" if a["same_machine"] and Path("/sys/firmware/efi").is_dir() else "manual"
    )
    a["firmware"] = w.choice(
        "Boot setup",
        ("manual", "uefi", "bios"),
        detected if a["installation"] == "new" else "manual",
        help=(
            "manual: copy/review the target's existing boot.loader settings in configuration.nix before building. "
            "uefi: systemd-boot, needs an EFI partition mount point. bios: GRUB, needs the whole boot disk. "
            "Firmware detection applies only when running on the target. Existing installations default to manual review."
        ),
    )
    a["boot_path"] = ""
    a["boot"] = (
        "  # REQUIRED before building: copy/review the target boot.loader settings here."
    )
    if a["firmware"] == "uefi":
        a["boot_path"] = w.ask(
            "EFI partition mount point (check target mounts with findmnt)",
            "/boot",
            lambda v: checked(
                v,
                r"/[A-Za-z0-9_/-]+",
                "Use an absolute EFI mount point such as /boot or /boot/efi.",
            ),
        )
        a["boot"] = f"""  boot.loader.systemd-boot.enable = true;
  boot.loader.efi = {{
    canTouchEfiVariables = true;
    efiSysMountPoint = {nix_string(a["boot_path"])};
  }};"""
    elif a["firmware"] == "bios":

        def boot_disk(value):
            checked(
                value,
                r"/dev/[A-Za-z0-9_./:+-]+",
                "Use the whole /dev/ boot disk, preferably /dev/disk/by-id/...",
            )
            if ".." in value.split("/"):
                fail("Parent path components are not allowed.")
            return value

        a["boot_path"] = w.ask(
            "Whole boot disk (required; use lsblk on the target)", validate=boot_disk
        )
        a["boot"] = f"""  boot.loader.grub = {{
    enable = true;
    device = {nix_string(a["boot_path"])};
  }};"""
    if a["installation"] == "existing":
        print(
            "Keep a known-good generation, data backup and administrator session. Review account, network and boot changes before applying."
        )
        confirm(
            w,
            "Generate these login and system settings for review before replacing your existing configuration",
        )
    return a, files, secret_source


def next_steps(a):
    host, user = a["host"], a["user"]
    print(f"\nGenerated .#{host} for {user}. Original hosts and Git history kept.")
    print("1. Supply hardware-configuration.nix from the TARGET machine:")
    if a["installation"] == "existing":
        if a["same_machine"]:
            print(f"   cp /etc/nixos/hardware-configuration.nix hosts/{host}/")
        else:
            print(
                f"   Copy the target's /etc/nixos/hardware-configuration.nix to hosts/{host}/hardware-configuration.nix."
            )
    else:
        print(
            "   On the target, prepare and mount filesystems at /mnt first, then from this checkout:"
        )
        print(
            f"   sudo nixos-generate-config --root /mnt --show-hardware-config > hosts/{host}/hardware-configuration.nix"
        )
    if a["firmware"] == "manual":
        print(
            f"   REQUIRED: copy/review existing boot.loader settings in hosts/{host}/configuration.nix before building."
        )
    print(
        f"2. Edit hosts/{host}/profile.nix to select applications. None are selected yet."
    )
    stage = f"git add hosts/{host} flake/hosts.nix"
    if a["mode"] == "local":
        stage += f" .sops.yaml secrets/hosts/{host}.yaml"
    print(
        "3. Review hardware, boot, accounts and git status --short, then stage reviewed files and validate:"
    )
    print(f"   {stage}\n   just check --no-build\n   just build {host}")
    if a["mode"] != "none":
        print(
            "   REQUIRED before deployment: provision the matching protected age identity at /var/lib/sops-nix/key.txt on the target."
        )
    if a["password_file"]:
        print(
            f"   REQUIRED before deployment: provision and verify runtime hash file {a['password_file']} on the target."
        )
    print(
        "4. After the build passes, run on the TARGET with recovery access available:"
    )
    if a["installation"] == "existing":
        print(
            "   First open a separate root recovery shell with sudo -s and keep it open."
        )
        print("   In this checkout:")
        print(f"   just switch {host}")
    else:
        flags = ""
        if a["private_ref"]:
            flags = f" --override-input private {shlex.quote(a['private_ref'])}"
        print(f"   sudo nixos-install --flake .#{host}{flags} --no-write-lock-file")
    if a["auth"] == "password":
        print(
            "   LOGIN SETUP IS INCOMPLETE for a new account. Before logout or reboot, set its password:"
        )
        if a["installation"] == "existing":
            print(
                "   Use the root recovery shell if the old account no longer has sudo access:"
            )
            print(f"   sudo passwd {user}")
        else:
            print(f"   sudo nixos-enter --root /mnt -c 'passwd {user}'")
        print(
            "   Existing account passwords survive rebuilds. Verify login and sudo before closing recovery access."
        )
    else:
        print("   Verify login and sudo before closing recovery access.")
    print(
        f"\nLater, after successful boot, login and sudo, optional cleanup: ./setup.sh --finish {host}"
    )
    print("Setup did not generate hardware, install, activate, or test boot/login.")


def main():
    for command in ("git", "nix"):
        if not shutil.which(command):
            fail(f"Required command is missing: {command}")
    if len(sys.argv) == 3 and sys.argv[1] == "--finish":
        finish(sys.argv[2])
        return
    if len(sys.argv) != 1:
        fail("Usage: ./setup.sh [--finish HOST]")
    print(
        "My NixOS setup — personalize an x86_64-linux host; no installation or activation.\n"
        "Enter accepts defaults. ? explains a question. :back returns to the previous question.\n"
        ":cancel or Ctrl-C cancels. Nothing is written until you confirm the review."
    )
    wizard = Wizard()
    registration = ROOT / "flake/hosts.nix"
    if registration.is_symlink() or registration.parent.is_symlink():
        fail("Refusing to edit symlinked host registration.")
    hosts_text = registration.read_text()
    while True:
        wizard.cursor = 0
        try:
            a, files, source = collect(wizard)
            files = host_files(a, dict(files), source, hosts_text)
            wizard.step(5, "Review and generate")
            private_summary = a["mode"]
            if a["mode"] == "external":
                private_summary += f" ({a['private_ref']})"
            elif a["mode"] == "local":
                private_summary += f" (secrets/hosts/{a['host']}.yaml)"
            print(
                f"Machine: {a['host']} ({a['kind']}); user: {a['user']}\n"
                f"Private configuration: {private_summary}; login: {a['auth']}\n"
                f"System: {a['installation']}; state versions: {a['system_state']} / {a['home_state']}\n"
                f"Boot: {a['firmware']} {a['boot_path']}; SSH: {'enabled, firewall open' if a['ssh_key'] else 'off'}\n"
                f"Timezone: {a['zone']}; locale: {a['locale']}; network: {'NetworkManager' if a['kind'] == 'desktop' else 'wired DHCP'}"
            )
            if a["auth"] == "password":
                print(
                    "Password: existing password kept; NEW account requires passwd before logout/reboot."
                )
            if a["password_file"]:
                print(
                    f"Runtime password-hash file: {a['password_file']} (provision on target before deployment)."
                )
            if a["firmware"] == "manual":
                print("Boot settings still require manual completion before building.")
            print("Write:\n" + "\n".join(f"  {p.relative_to(ROOT)}" for p in files))
            action = wizard.choice(
                "Generate files, edit a stage, or cancel",
                ("generate", "edit", "cancel"),
                "edit",
            )
            if action == "cancel":
                raise KeyboardInterrupt
            if action == "edit":
                step = wizard.choice(
                    "Stage to edit: 1 machine, 2 user, 3 private, 4 system",
                    ("1", "2", "3", "4"),
                    "1",
                )
                wizard.answers = wizard.answers[: wizard.steps[int(step)]]
                continue
            confirm(wizard, "Write the files listed above")
            break
        except Back:
            continue
    host_dir = ROOT / "hosts" / a["host"]
    if (
        registration.is_symlink()
        or registration.read_text() != hosts_text
        or host_dir.exists()
        or host_dir.is_symlink()
    ):
        fail("Host files changed while setup was running; nothing was written.")
    for path in files:
        if path != registration and (path.exists() or path.is_symlink()):
            fail(
                f"Destination appeared while setup was running: {path.relative_to(ROOT)}. Nothing was written."
            )
        if any(
            (ROOT / parent).is_symlink()
            for parent in path.relative_to(ROOT).parents
            if parent != Path(".")
        ):
            fail("Refusing to write through symlinked directories.")
    write_files(files)
    next_steps(a)


if __name__ == "__main__":
    try:
        main()
    except (EOFError, KeyboardInterrupt, Back):
        print("\nCancelled. Completed operations, if any, are kept.", file=sys.stderr)
        sys.exit(1)
    except (ValueError, OSError, subprocess.CalledProcessError) as error:
        print(f"Setup stopped: {error}", file=sys.stderr)
        sys.exit(1)
