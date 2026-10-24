# Hosts

I use separate configurations for my PC, laptop, and server. To add your own,
start with [the host template](../templates/host/README.md). The flake targets
`x86_64-linux`.

You'll need Git, just, and Nix with flakes enabled. Replace `my-host` below with
your machine's name.

## 1. Copy the template

```sh
git clone https://github.com/evgen2571/my-nixos.git
cd my-nixos
cp -r templates/host hosts/my-host
```

## 2. Add your hardware configuration

For a fresh installation, follow the [NixOS installation manual](https://nixos.org/manual/nixos/stable/#sec-installation)
to boot the installer and prepare and mount your disks at `/mnt`. Back up your
data before changing partitions, then generate the hardware configuration:

```sh
sudo nixos-generate-config --root /mnt
sudo cp /mnt/etc/nixos/hardware-configuration.nix hosts/my-host/
sudo chown "$(id -u):$(id -g)" hosts/my-host/hardware-configuration.nix
```

On an existing NixOS installation, copy `/etc/nixos/hardware-configuration.nix`
instead. Keep its working boot, mount, login, and state-version settings.

## 3. Configure the machine and user

In `hosts/my-host/configuration.nix`, set your hostname, username, bootloader,
networking, timezone, and state versions. The template locks the account password
and disables mutable users: an SSH key alone won't let you use password-based
sudo or graphical login. Set up persistent authentication and an explicit SSH
firewall rule using the [installation checklist](../templates/host/README.md#before-you-install).

The commented [desktop](../modules/core/desktop-baseline.nixos.nix) and
[server](../modules/core/server-baseline.nixos.nix) baselines both assume
systemd-boot. Read yours before enabling it; the desktop baseline also includes
my keyboard layout and packages. Choose at most one, or set these options yourself.

## 4. Register the host

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
`secretSource = "none"` lets you start without a private repository. Leave services
that need credentials off until you've set up [your own secrets](../docs/secrets.md).

## 5. Pick your features

Uncomment the features you want in `hosts/my-host/profile.nix`.
[Modules](../modules/README.md) explains the option paths and individual switches.

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

This enables Niri, the greeter, Noctalia, and Kitty.
Edit the existing entries to avoid duplicate definitions. Noctalia has `pc` and
`laptop` layouts; choose one and review its display settings. Adjust the shared
[Niri startup commands and shortcuts](../config/niri/README.md) for the apps
you've enabled.

The workstation bundle enables several development tools together; individual
`false` settings override its defaults.

## 6. Check and build

Stage the new files so Git-backed flakes can see them, then evaluate and build:

```sh
git add hosts/my-host flake/hosts.nix
just check --no-build
just build my-host
```

These evaluate the flake and build your host without activating it. Boot and login
still need checking on the machine.

## 7. Install or apply

Review your mounts, bootloader, and login settings. From the installer, run
`sudo nixos-install --flake .#my-host` and follow the manual for rebooting.
On an existing NixOS system, use `just switch my-host`.

After booting, check local login, sudo, networking, and SSH from another machine.
For the desktop example, also check the greeter, Niri session, terminal, and audio.
Keep the installer or a known-good generation available. See
[maintenance and recovery](../docs/maintenance.md) for rollback.
