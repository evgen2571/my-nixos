# Try this configuration

Start with your own host. My PC, laptop, and server outputs need my private input.
Your host can use the public repo on its own.

## 1. Before you start

You need an `x86_64-linux` NixOS machine, internet access, and local console access.
Back up your current configuration and important data. Keep a working boot
entry and installation USB around while you try this.

For a fresh install, follow the [NixOS installation manual](https://nixos.org/manual/nixos/stable/#sec-installation)
through partitioning and mounting at `/mnt`, then continue here in the installer.
On an existing system, leave your disks alone.

Get the tools in a temporary shell and enable flakes for this shell:

```sh
nix-shell -p git just mkpasswd
export NIX_CONFIG='experimental-features = nix-command flakes'
```

## 2. Clone the repo

```sh
git clone https://github.com/evgen2571/my-nixos.git
cd my-nixos
```

## 3. Copy the template

Replace `my-host` with your host name throughout this guide.

```sh
cp -r templates/host hosts/my-host
```

## 4. Add your hardware configuration

On an existing installation:

```sh
cp /etc/nixos/hardware-configuration.nix hosts/my-host/
```

For a fresh install, with the target filesystems mounted at `/mnt`:

```sh
sudo nixos-generate-config --root /mnt
sudo cp /mnt/etc/nixos/hardware-configuration.nix hosts/my-host/
sudo chown "$(id -u):$(id -g)" hosts/my-host/hardware-configuration.nix
```

If your setup uses other hardware modules, copy those and update the imports too.

## 5. Configure the machine and user

Edit `hosts/my-host/configuration.nix`:

- Set `networking.hostName` and `my.primaryUser.name`. On an existing system,
  keep your login name and any explicit UID/GID so your files stay yours.
  Carry over other accounts you need; immutable users remove unmanaged accounts.
- Copy your working bootloader, disk encryption, mounts, swap, and networking
  settings from your current configuration. Hardware generation doesn't cover
  all of these. The commented systemd-boot example is for UEFI machines.
- The template uses NetworkManager. Keep your existing network setup if different;
  don't enable competing managers. Set your timezone and locale too.
- Keep your existing `system.stateVersion` and Home Manager `home.stateVersion`.
  For a new installation, use the installed release; the template starts at `26.05`.

The user is in `wheel` for password-based sudo. Its password comes from a
root-owned file outside Git and the Nix store. Create it **before activation**.
Use `target=/mnt` for a fresh install, or `target=/` on an existing system:

```sh
target=/
sudo install -d -m 700 "$target/var/lib/my-nixos"
set -o pipefail
mkpasswd -m yescrypt | sudo tee "$target/var/lib/my-nixos/login-password" >/dev/null
sudo chmod 600 "$target/var/lib/my-nixos/login-password"
sudo test -s "$target/var/lib/my-nixos/login-password"
```

Enter the password at the prompt. Stop if any command fails.
Keep this file backed up and outside the repo.
With `users.mutableUsers = false`, rebuilds restore this password, so update the
file to change it; `passwd` alone won't persist. Missing or empty files can lock
you out. Checking and building cannot verify this runtime file.

SSH is off by default. For remote access, enable `my.server.ssh.enable`, add your
public key to `my.primaryUser.authorizedKeys`, and allow its port on the intended
firewall interface. Password and root SSH login stay off. See [secrets](../docs/secrets.md)
when you want SOPS or services that need credentials.

## 6. Register the host

Add this inside `flake.nixosConfigurations` in `flake/hosts.nix`:

```nix
my-host = mkHost {
  host = "my-host";
  hostModule = ../hosts/my-host/configuration.nix;
  profile = moduleProfiles.all;
  secretSource = "none";
};
```

This makes the optional modules available. It doesn't enable them or require a
private repository. Leave credential-dependent services disabled for now.

## 7. Add a desktop

In `hosts/my-host/profile.nix`, uncomment `my.desktop.niri.enable`,
`my.desktop.noctaliaGreeter.enable`, `my.primaryUser.home.settings.my.user.desktop.noctalia.enable`,
and `my.primaryUser.home.settings.my.user.dev.kitty.enable`. Set each to `true`.
Leave `niriConfig.enable` commented for this small example. Add this inside the
existing `my.primaryUser.home.settings` block:

```nix
xdg.configFile."niri/config.kdl".text = ''
  input { keyboard { xkb { layout "us"; }; }; }
  binds {
    Mod+Return { spawn "kitty"; }
    Mod+Space { spawn "noctalia" "msg" "panel-toggle" "launcher"; }
    Mod+Q { close-window; }
    Mod+Left { focus-column-left; }
    Mod+Right { focus-column-right; }
    Mod+Up { focus-window-up; }
    Mod+Down { focus-window-down; }
    Mod+Shift+E { quit; }
  }
'';
```

Niri, the login screen, Noctalia, Kitty, and audio are enough to get started.
`Mod` is Super (the Windows key). Use Super+Return for a terminal and Super+Space
for the launcher. Change the keyboard layout above to yours. Other apps stay
optional; see [modules](../modules/README.md). My [full Niri config](../config/niri/README.md)
has app shortcuts and monitor settings you'll need to adapt before enabling it.

## 8. Check and build

```sh
git add hosts/my-host flake/hosts.nix
just check --no-build
just build my-host
```

Git-backed flakes only see tracked files, so stage new files first.
The check evaluates the flake. The build produces `result`, your system closure.
Neither activates anything or tests boot, login, or your password file.

## 9. Try or install

On an existing system, save your work and run
`sudo nixos-rebuild test --flake .#my-host`. This changes the running system,
including services and accounts, but keeps the previous boot default. Reboot to
return to it. Rollback doesn't restore the password file or your personal data.
Check local login, sudo, networking, and the desktop before making it permanent
with `just switch my-host`. Check SSH too if you enabled it.

For a fresh install, check your mounts, bootloader, and password file under `/mnt`
once more, then run `sudo nixos-install --flake .#my-host`. Follow the manual to
reboot. No disk formatting is needed at this step.

If activation fails, use your console or a known-good boot entry. For a permanent
switch, `sudo nixos-rebuild switch --rollback` restores the previous generation.
Keep backups of writable data; see [recovery](../docs/maintenance.md).
