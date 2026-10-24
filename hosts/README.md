# Hosts

The PC, laptop, and server directories are for my own machines. Their hardware, boot setup, accounts, and private inputs aren't generic defaults.

To make a new host, start with [the template](../templates/host/) instead.

## Your own host

On an installer, prepare and mount your disks at `/mnt` first. That's standard NixOS installation work; I'm not wrapping it in another installer.

```sh
git clone https://github.com/evgen2571/my-nixos.git
cd my-nixos
cp -r templates/host hosts/my-host

sudo nixos-generate-config --root /mnt
sudo cp /mnt/etc/nixos/hardware-configuration.nix hosts/my-host/
sudo chown "$(id -u):$(id -g)" hosts/my-host/hardware-configuration.nix
```

In `hosts/my-host/configuration.nix`, set the hostname, username, state versions, bootloader, networking, and your **public** SSH key. The template locks password login and requires an explicit SSH firewall rule. You'll also need a usable way to log in before you install. Check the hardware file against your actual disks; never copy another machine's UUIDs.

Then add an output in [`flake/hosts.nix`](../flake/hosts.nix), next to my existing hosts:

```nix
my-host = mkHost {
  host = "my-host";
  hostModule = ../hosts/my-host/configuration.nix;
  profile = moduleProfiles.all;
  secretSource = "none";
};
```

The `all` catalog profile makes every optional module *available*. It doesn't enable them. The copied `hosts/my-host/profile.nix` lists every feature: uncomment the ones you want and configure the settings noted beside them. The narrower `moduleProfiles.desktop` and `moduleProfiles.server` are still available if you remove template settings outside their scope. See [modules](../modules/README.md) for the option layout.

Stage new files so flakes can see them, then check and build:

```sh
git add hosts/my-host flake/hosts.nix
nix flake check --no-build --no-write-lock-file
nix build --no-link .#nixosConfigurations.my-host.config.system.build.toplevel --no-write-lock-file
```

A build doesn't mean it will boot or that SSH works. Check your mounts and access again before `nixos-install --flake .#my-host`. Follow the [NixOS installation manual](https://nixos.org/manual/nixos/stable/#sec-installation) for the actual install, reboot, and recovery.

Start without secrets. If a feature needs credentials, read [the secrets note](../docs/secrets.md) before enabling it.
