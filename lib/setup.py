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


def ask(label, default=""):
    prompt = f"{label} [{default}]" if default else label
    value = input(f"{prompt}: ").strip() or default

    if any(ord(c) < 32 or ord(c) == 127 for c in value):
        fail("Control characters are not allowed.")
    return value


def choice(label, values, default):
    value = ask(f"{label} ({'/'.join(values)})", default)
    if value not in values:
        fail(f"Choose one of: {', '.join(values)}.")
    return value


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


def write_files(files):
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
    except BaseException:
        # Roll back earlier writes on errors and Ctrl-C, without touching the Git index.
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


def main():
    if len(sys.argv) != 1:
        fail("Usage: ./setup.sh (interactive; no arguments)")
    for command in ("git", "nix"):
        if not shutil.which(command):
            fail(f"Required command is missing: {command}")

    print(
        "My NixOS setup: x86_64-linux only. No installation or activation.\n"
        "Press Ctrl-C at any prompt to cancel. Repository files stay unchanged until confirmation."
    )

    # 1. Choose the private source; keep personal paths out of flake.lock.
    mode = choice("Private source", ("none", "local", "external"), "none")
    private = None

    if mode == "external":
        print(
            "Use a reviewed directory containing a private flake. Its source enters the Nix store;\n"
            "it must contain only Nix configuration and encrypted secrets, never plaintext credentials or keys."
        )
        private = (
            Path(ask("Existing private directory (absolute or relative path)"))
            .expanduser()
            .resolve(strict=True)
        )
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
        if git_root.returncode and ((private / ".git").exists() or (private / ".git").is_symlink()):
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

    # 2. Collect host details, boot settings and a usable login method.
    host = ask("Hostname")
    if not re.fullmatch(r"[a-z][a-z0-9-]{0,61}[a-z0-9]|[a-z]", host):
        fail("Use a lowercase hostname of 1–63 letters, digits or hyphens, starting with a letter.")

    registration = ROOT / "flake/hosts.nix"
    hosts_text = registration.read_text()
    host_dir = ROOT / "hosts" / host
    if (
        host_dir.exists()
        or host_dir.is_symlink()
        or re.search(rf'^\s*"?{re.escape(host)}"?\s*=', hosts_text, re.M)
    ):
        fail("That host directory or flake output already exists; setup will not overwrite it.")

    kind = choice("Host type", ("desktop", "laptop", "server"), "desktop")

    user = ask("Username")
    if not re.fullmatch(r"[a-z_][a-z0-9_-]{0,30}", user) or user in (
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
        fail(
            "Choose a non-system login name using lowercase letters, digits, underscores or hyphens."
        )
    if mode == "external" and user == "operator":
        fail("The private deployment guard requires a personal username instead of operator.")

    full_name = ask("Full name (optional)")
    git_name = ask("Git author name (optional)")
    git_email = ask("Git author email (optional)")
    if git_email and not re.fullmatch(r"[^\s@]+@[^\s@]+", git_email):
        fail("Invalid Git email address.")

    zone = ask("Timezone", "UTC")
    zone_path = Path("/usr/share/zoneinfo")
    if not zone_path.exists():
        zone_path = Path("/etc/zoneinfo")
    if (
        zone.startswith("/")
        or not re.fullmatch(r"[A-Za-z0-9_+/-]+", zone)
        or ".." in zone.split("/")
        or not (zone_path / zone).is_file()
    ):
        fail("Choose an installed timezone, for example UTC or Europe/Berlin.")
    locale = ask("UTF-8 locale", "en_US.UTF-8")
    if not re.fullmatch(r"[a-z]{2,3}_[A-Z]{2}\.UTF-8", locale):
        fail("Use a UTF-8 locale such as en_US.UTF-8 (Nix will check availability).")

    print(
        "For an existing installation, keep BOTH original state versions; never use the current release by default."
    )
    installation = choice(
        "Target installation",
        ("new", "existing"),
        "existing" if Path("/etc/NIXOS").exists() else "new",
    )
    system_state = ask(
        ("Original system.stateVersion" if installation == "existing" else "NixOS state version"),
        "" if installation == "existing" else "26.05",
    )
    home_state = ask(
        (
            "Original Home Manager home.stateVersion"
            if installation == "existing"
            else "Home Manager state version"
        ),
        "" if installation == "existing" else "26.05",
    )
    for version in (system_state, home_state):
        if not re.fullmatch(r"\d{2}\.(03|05|09|11)", version) or not "15.09" <= version <= "26.05":
            fail("Enter the original release state version (at most 26.05).")

    firmware = choice("Boot firmware", ("uefi", "bios"), "uefi")
    if firmware == "uefi":
        boot_path = ask("Existing EFI system partition mount point", "/boot")
        if not re.fullmatch(r"/[A-Za-z0-9_/-]+", boot_path) or ".." in boot_path.split("/"):
            fail("Use an absolute EFI mount point such as /boot or /boot/efi.")
        boot = f"""  boot.loader.systemd-boot.enable = true;
  boot.loader.efi = {{
    canTouchEfiVariables = true;
    efiSysMountPoint = {nix_string(boot_path)};
  }};"""
    else:
        boot_path = ask("GRUB boot disk (prefer /dev/disk/by-id/...)")
        if not re.fullmatch(r"/dev/[A-Za-z0-9_./:+-]+", boot_path) or ".." in boot_path.split("/"):
            fail("Use an absolute /dev/ disk path.")
        boot = f"""  boot.loader.grub = {{
    enable = true;
    device = {nix_string(boot_path)};
  }};"""

    print(
        "Authentication: 'password-file' uses an existing protected runtime file containing a crypt password hash.\n"
        "Its contents are never read by setup or copied into Nix. 'ssh' locks console/password login\n"
        "and grants wheel passwordless sudo; keep the matching SSH private key safe."
    )
    auth_choices = ("password-file", "ssh") if mode == "none" else ("sops", "password-file", "ssh")
    if mode != "none":
        print(
            "'sops' uses the encrypted user_password_hash field in the selected host YAML.\n"
            "Provision its matching protected age identity at /var/lib/sops-nix/key.txt on the target before deployment."
        )

    if mode != "none":
        default_auth = "sops"
    elif kind == "server":
        default_auth = "ssh"
    else:
        default_auth = "password-file"

    auth = choice("Authentication", auth_choices, default_auth)
    password_file = None

    if auth == "password-file":
        password_file = source_path(
            ask("Runtime password-hash file (must also exist on the target)")
        )
        info = password_file.stat()
        if (
            password_file == ROOT
            or ROOT in password_file.parents
            or Path("/nix/store") in password_file.parents
            or info.st_mode & 0o077
            or info.st_uid not in (0, os.getuid())
            or not info.st_size
        ):
            fail(
                "The runtime hash file must be nonempty, owner-only, outside the repository and Nix store."
            )
        print(
            "Provision this exact path with a valid crypt hash on the target BEFORE installing/applying.\n"
            "Setup cannot verify the password, target provisioning, or console login."
        )

    ssh_key = ask(
        "SSH public key FILE" + (" (optional)" if auth != "ssh" and kind != "server" else "")
    )
    keys = "[ ]"
    if ssh_key:
        if not shutil.which("ssh-keygen"):
            fail("ssh-keygen is required to validate the SSH public key.")
        key_path = source_path(ssh_key)
        if key_path.stat().st_size > 16384:
            fail("Expected one SSH public key, not a private key or large file.")
        # Check the header before reading the rest; never load a private key.
        with key_path.open() as key_file:
            prefix = key_file.read(20)
        if not re.match(r"(?:ssh-|ecdsa-|sk-)", prefix):
            fail("Expected an OpenSSH public key file; private keys are never accepted.")
        key = key_path.read_text().strip()
        if "\n" in key or not re.fullmatch(
            r"(?:ssh-|ecdsa-|sk-)[A-Za-z0-9@._+-]+ [A-Za-z0-9+/=]+(?: [^\r\n]*)?", key
        ):
            fail("Expected one plain OpenSSH public key without authorized_keys options.")
        subprocess.run(
            ["ssh-keygen", "-l", "-f", str(key_path)],
            check=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        keys = f"[ {nix_string(key)} ]"
    elif auth == "ssh" or kind == "server":
        fail("This authentication/host type requires an SSH public key.")
    if (
        auth == "ssh"
        and choice("Accept locked console login and passwordless sudo", ("yes", "no"), "no")
        != "yes"
    ):
        fail("Cancelled: choose runtime password authentication instead.")

    # 3. Validate selected ciphertext and prepare ordinary host files before writing.
    files = {}
    secret_source = {"none": "none", "local": "local", "external": "private"}[mode]
    if mode == "local":
        ciphertext = source_path(
            ask("Existing SOPS-encrypted host YAML", f"secrets/hosts/{host}.yaml")
        )
        policy_dest = ROOT / ".sops.yaml"
        if policy_dest.is_symlink():
            fail("The local recipient policy must not be a symlink.")
        policy = (
            policy_dest
            if policy_dest.is_file()
            else source_path(ask("Existing SOPS recipient policy (.sops.yaml)"))
        )
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

    if auth == "sops" and not re.search(
        r"^user_password_hash: ENC\[AES256_GCM,.+type:str\]$",
        Path(ciphertext).read_text(),
        re.M,
    ):
        fail(
            "SOPS authentication requires an encrypted user_password_hash string in the selected YAML."
        )

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

    print(
        f"\nCreate hosts/{host}/configuration.nix and profile.nix; register .#{host}.\n"
        f"Type: {kind}; user: {user}; secrets: {secret_source}; boot: {firmware} {boot_path}.\n"
        "No hardware configuration will be generated. SSH, when enabled, opens its firewall port."
    )
    print("Write:\n" + "\n".join(f"  {path.relative_to(ROOT)}" for path in files))
    if choice("Write this configuration", ("yes", "no"), "no") != "yes":
        fail("Cancelled; no configuration was written.")

    if registration.read_text() != hosts_text or host_dir.exists() or host_dir.is_symlink():
        fail("Host files changed while setup was running; nothing was written.")
    if any(path != registration and (path.exists() or path.is_symlink()) for path in files):
        fail("A destination appeared while setup was running; refusing to overwrite it.")
    write_files(files)

    # 4. Offer cleanup only after a complete host exists, with separate confirmations.
    cleaned = False
    fresh = False
    print("\nHost generated. Optional cleanup follows; cancelling now keeps the generated host.")
    if choice("Remove original PC, laptop and server hosts", ("yes", "no"), "no") == "yes":
        removed = []
        new_registration = files[registration].decode()
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
                fail("Original host registrations have changed; review cleanup manually.")
        justfile = ROOT / "justfile"
        recipes = justfile.read_text().replace('host := "nixos-pc"', f'host := "{host}"')
        alias_pattern = (
            r"\n(?:build|dry|switch|boot)-(?:pc|lp|server) [^\n]*\n(?:[ \t]+[^\n]*\n|\n)*"
        )
        aliases = re.findall(alias_pattern, recipes)
        recipes = re.sub(
            alias_pattern,
            "",
            recipes,
        )
        print("Remove exactly:\n" + "\n".join(f"  {p.relative_to(ROOT)}" for p in sorted(removed)))
        print(
            "Remove the now-empty hosts/pc, hosts/laptop and hosts/server directories;\n"
            "remove flake registrations nixos-pc, nixos-lp and nixos-server;\n"
            f"set the default just host to {host}. Shared modules, secrets and workspace presets stay."
        )
        print(
            "Remove justfile recipes: " + ", ".join(alias.strip().split()[0] for alias in aliases)
        )
        if ask("Type 'remove original hosts' to confirm") == "remove original hosts":
            write_files(
                {
                    registration: new_registration.encode(),
                    justfile: recipes.encode(),
                    **{path: None for path in removed},
                }
            )
            for name in ("pc", "laptop", "server"):
                directory = ROOT / "hosts" / name
                if directory.exists():
                    directory.rmdir()
            cleaned = True

    if (
        choice(
            "Start a fresh Git repository (discard ALL existing Git history)",
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
        backup = ROOT / ".git.setup-backup"
        if backup.exists() or backup.is_symlink() or (git_dir / "worktrees").exists():
            fail(
                "Review existing Git backups or linked worktrees manually before discarding history."
            )
        if any(
            os.environ.get(name)
            for name in ("GIT_DIR", "GIT_WORK_TREE", "GIT_INDEX_FILE", "GIT_COMMON_DIR")
        ):
            fail("Unset Git directory/index environment overrides before fresh initialization.")
        print(
            f"Remove exactly: {git_dir}\nThis discards history, branches, remotes, hooks, index and Git configuration.\n"
            "Working files stay. Nothing will be staged, committed or published."
        )
        if ask("Type 'start fresh' to confirm") == "start fresh":
            try:
                git_dir.rename(backup)
                subprocess.run(["git", "init", "-b", "main"], cwd=ROOT, check=True)
            except BaseException:
                if backup.exists():
                    if git_dir.exists():
                        shutil.rmtree(git_dir)
                    backup.rename(git_dir)
                raise
            shutil.rmtree(backup)
            fresh = True

    # 5. Print the remaining manual steps; never install or activate here.
    stage = f"git add hosts/{host} flake/hosts.nix"
    if cleaned:
        stage = f"git add -A -- hosts/{host} hosts/pc hosts/laptop hosts/server flake/hosts.nix justfile"
    if fresh:
        stage = "git add .gitignore flake.nix flake.lock flake lib modules pkgs config templates hosts assets justfile setup.sh"
    if mode == "local":
        stage += f" .sops.yaml secrets/hosts/{host}.yaml"
    hardware = (
        f"cp /etc/nixos/hardware-configuration.nix hosts/{host}/"
        if installation == "existing"
        else f"sudo nixos-generate-config --root /mnt --show-hardware-config > hosts/{host}/hardware-configuration.nix"
    )
    print(
        f"\nGenerated .#{host} for {user} ({kind}, {secret_source}).\n"
        f"1. Supply real hardware configuration (for a new install, mount the target at /mnt first):\n"
        f"   {hardware}\n"
        f"   Review boot, mounts and networking in hosts/{host}/configuration.nix.\n"
        f"2. Edit hosts/{host}/profile.nix to enable individual applications and modules.\n"
        f"3. Review the files and git status --short, then stage reviewed sources for Git flakes:\n"
        f"   {stage}\n"
        f"   just check --no-build\n"
        f"   just build {host}\n"
        f"4. Use the standard NixOS installation or activation workflow after reviewing the build.\n"
        f"   Existing system: just switch {host}\n"
        f"   Installer (disks already prepared): sudo nixos-install --flake .#{host}\n"
        "Setup ran neither command. Keep console/recovery access; boot and login remain unverified."
    )
    if mode == "external":
        print(
            "just reads the ignored .env. For direct nix/nixos-install commands, also pass:\n"
            f"   --override-input private {shlex.quote(private_ref)} --no-write-lock-file"
        )
    if mode != "none":
        print(
            "Before deployment, provision the protected matching age identity at /var/lib/sops-nix/key.txt;\n"
            "setup never creates, reads or copies private identities."
        )
    if password_file:
        print(
            f"Before deployment, provision and verify the runtime password-hash file: {password_file}"
        )


if __name__ == "__main__":
    try:
        main()
    except (EOFError, KeyboardInterrupt):
        print("\nCancelled.", file=sys.stderr)
        sys.exit(1)
    except (ValueError, OSError, subprocess.CalledProcessError) as error:
        print(f"Setup stopped: {error}", file=sys.stderr)
        sys.exit(1)
