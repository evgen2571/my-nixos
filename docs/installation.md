# Installation and everyday work

`my-nixos` manages the maintainer's PC, laptop and server. Independent reuse is
supported by adapting its choices to your own hardware and services. The existing
host profiles describe real machines; they are not defaults for a new installation.

## Choose your starting point

| What you need | Start here |
| --- | --- |
| Rebuild or update the existing PC, laptop or server | [Maintainer builds and deployment](deployment-checklist.md) |
| Understand the configuration or change an app/module | [Architecture](../ARCHITECTURE.md), then [task routing](task-routing.md) |
| Adapt the repository to your own machine | [New machine without secrets](#new-machine-without-secrets) below |
| Add encrypted credentials to your own host | [Single-repository SOPS](sops.md#single-repository-setup) |
| Restore an existing host or recover access | [Restore](deployment-checklist.md#restore-an-existing-host) and [rollback](deployment-checklist.md#rollback-and-recovery) |

All builds start in this repository. The input/command syntax was tested with
Nix 2.34.8; older relative-path lock behavior is unverified. Recorded host and VM
results are in [M03 validation](m03-validation.md).

## New machine without secrets

This path uses one checkout and your own host definition. Start by reading the
[NixOS installation manual](https://nixos.org/manual/nixos/stable/#sec-installation)
for installation media, networking, partitioning, encryption and mounting.

### 1. Prepare and copy

**Disk preparation changes the target and can destroy data.** Follow the manual
for your hardware, mounting its root at `/mnt` and its boot/other filesystems
under that root. Keep a local console available.

From installation media, copy the template and generate the target's hardware
configuration. These commands write checkout files and `/mnt/etc/nixos`; they do
not install or activate a system:

```sh
git clone https://github.com/evgen2571/my-nixos.git
cd my-nixos
cp -r templates/host hosts/my-host
sudo nixos-generate-config --root /mnt
sudo cp /mnt/etc/nixos/hardware-configuration.nix hosts/my-host/hardware-configuration.nix
sudo chown "$(id -u):$(id -g)" hosts/my-host/hardware-configuration.nix
```

Review the generated mounts, UUIDs, swap and encryption against the target.
A supported hardware module may replace this declaration if it describes that
machine. Never reuse another host's disk identifiers.

### 2. Choose hardware, features and first access

Edit `hosts/my-host/configuration.nix`: choose the hostname, timezone, bootloader,
networking and primary username. Set NixOS/Home Manager state versions for this
initial installation. Select features in `hosts/my-host/profile.nix` using
[the existing modules](modules.md).

The template uses key-only SSH. Replace its empty `authorizedKeys` list inside
`my.primaryUser` with your **public** key:

```nix
authorizedKeys = [ "YOUR_SSH_PUBLIC_KEY" ];
```

Then add an explicit reachable SSH port/interface and administration policy. For
the default SSH port:

```nix
networking.firewall.allowedTCPPorts = [ 22 ];
security.sudo.wheelNeedsPassword = false;
```

The last setting lets your trusted wheel user administer this new host without a
password. Root and password login remain locked. Keep the matching client key and
console available; no password or private key belongs in the configuration.

### 3. Register and build

Inside `flake/hosts.nix`'s `flake.nixosConfigurations`, add:

```nix
my-host = mkHost {
  host = "my-host";
  hostModule = ../hosts/my-host/configuration.nix;
  profile = moduleProfiles.server; # choose desktop for workstation modules
  system = "x86_64-linux"; # select the target architecture
  secretSource = "none";
};
```

**No activation:** stage the new files so the Git flake sees them, then evaluate
and build from the checkout:

```sh
git add hosts/my-host flake/hosts.nix
nix flake check --no-build --no-write-lock-file
nix build --no-link .#nixosConfigurations.my-host.config.system.build.toplevel --no-write-lock-file
```

`--no-build` evaluates checks only. Run `nix flake check --no-write-lock-file` to
execute available checks. A successful build does not test physical boot or SSH.

### 4. Install and verify access

**Changes the mounted target, system profile and boot state.** Check `lsblk -f`
and `findmnt -R /mnt` against your disk plan before running:

```sh
sudo nixos-install --root /mnt --flake .#my-host --no-root-passwd --no-write-lock-file
```

Keep a recoverable checkout on the target. After reboot, test a login from your
client using `ssh -i /protected/client-key YOUR_USER@YOUR_HOST`, then `id`,
`sudo -v` and `systemctl --failed`. Verify a second login before releasing the
console. `--no-root-passwd` leaves root locked and relies on the user access above.

## Ongoing changes

Use [Making a change](../README.md#making-a-change) and
[task routing](task-routing.md) for public modules, host profiles and app dotfiles.
Build affected hosts before activating changes. Credential editing belongs in the
[SOPS guide](sops.md); existing-host updates and recovery are in the
[maintainer guide](deployment-checklist.md).
