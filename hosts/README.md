# Hosts

Start with [the host template](../templates/host/README.md) for your machine.
The PC, laptop, and server directories contain my hardware and private settings.
The flake currently targets `x86_64-linux`.

You'll need Git and Nix with flakes enabled. These steps use `my-host` as the
machine name; replace it with yours throughout.

## 1. Prepare your hardware configuration

For a fresh installation, boot the NixOS installer, then prepare and mount your
disks at `/mnt` using the [NixOS installation manual](https://nixos.org/manual/nixos/stable/#sec-installation).
Back up anything you need before changing partitions.

```sh
git clone https://github.com/evgen2571/my-nixos.git
cd my-nixos
cp -r templates/host hosts/my-host
```

Generate the hardware configuration from the mounted disks:

```sh
sudo nixos-generate-config --root /mnt
sudo cp /mnt/etc/nixos/hardware-configuration.nix hosts/my-host/
sudo chown "$(id -u):$(id -g)" hosts/my-host/hardware-configuration.nix
```

If you're adapting an existing NixOS installation, copy its hardware configuration
from `/etc/nixos/hardware-configuration.nix` instead. Keep its working boot, mount,
access, and state-version settings while you get the new configuration running.

## 2. Configure the machine and login

In `hosts/my-host/configuration.nix`, set your hostname, username, bootloader,
networking, timezone, and state versions. Review the
[before-installation checklist](../templates/host/README.md#before-you-install),
including SSH, sudo, and graphical login. The template locks the account password,
so you need to choose how you'll authenticate before installing.

The commented [desktop](../modules/core/desktop-baseline.nixos.nix) and
[server](../modules/core/server-baseline.nixos.nix) baseline imports provide boot and other defaults.
Read the one you want before uncommenting it: both assume systemd-boot, and the
desktop baseline includes my keyboard layout and package choices. Choose at most
one, or configure those settings yourself.

## 3. Add your flake output

In [`flake/hosts.nix`](../flake/hosts.nix), add this entry inside
`flake.nixosConfigurations`, alongside the existing hosts:

```nix
my-host = mkHost {
  host = "my-host";
  hostModule = ../hosts/my-host/configuration.nix;
  profile = moduleProfiles.all;
  secretSource = "none";
};
```

`moduleProfiles.all` makes every optional module available without enabling it.
`secretSource = "none"` lets you start without credentials or a private repository.
Keep services that need credentials disabled; add your own later using
[the secrets guide](../docs/secrets.md). My existing hosts still need their private
input for production builds.

## 4. Pick your features

In `hosts/my-host/profile.nix`, uncomment the features you want and read the
settings beside them. The template lists every optional feature; [modules](../modules/README.md)
explains the system and Home Manager option paths.

For a small Niri desktop, enable these settings in the existing blocks:

```nix
my.desktop.niri.enable = true;
my.desktop.noctaliaGreeter.enable = true;

my.primaryUser.home.settings.my.user = {
  desktop.niriConfig = {
    enable = true;
    workspaceProfile = "default";
  };
  desktop.noctalia = {
    enable = true;
    profile = "pc";
  };
  dev.kitty.enable = true;
};
```

This selects the session, login screen, user config, shell, and terminal. Edit the
existing entries rather than pasting duplicate definitions. Noctalia offers `pc`
and `laptop` layouts; choose the closer one and review its display settings.
The shared Niri startup commands and shortcuts also reference optional apps.
Adjust them for what you've installed using the [Niri guide](../config/niri/README.md).

You can add a browser, editor, and other tools once the desktop works. The
workstation bundle enables several tools at once; individual `false` settings
override its defaults.

## 5. Check and build

Stage the new files so Git-backed flakes can see them, then evaluate and build:

```sh
git add hosts/my-host flake/hosts.nix
nix flake check --no-build --no-write-lock-file
nix build --no-link .#nixosConfigurations.my-host.config.system.build.toplevel --no-write-lock-file
```

Evaluation catches configuration errors. The build checks packages and deployment
guards without activating the system. Neither proves that boot or login works.

## 6. Install and check the real machine

Review your mounts, bootloader, and login checklist again. On the installer,
install your host with `sudo nixos-install --flake .#my-host`, following the
[NixOS installation manual](https://nixos.org/manual/nixos/stable/#sec-installation)
for installation and reboot. If you're already running NixOS, follow
[updates and recovery](../docs/maintenance.md) to activate the configuration.

After booting, check local login, sudo, networking, and SSH from another machine.
For the desktop example, also check the greeter, Niri session, terminal, and audio.
Keep the installer available, or a known-good generation on an existing system.
The [recovery guide](../docs/maintenance.md) explains rollback and what it cannot
restore.
