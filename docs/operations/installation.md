# Install on your own machine

Start with a small host that boots and accepts your SSH key, then add the desktop
or services you want. I use the full profiles for my own machines; copying one
of those profiles would also copy its hardware and infrastructure assumptions.
This walkthrough uses a single checkout and no secrets. If you're updating one
of my existing hosts, use [production deployment](deployment.md).

## Before you start

You'll need Git, network access to public flake inputs and package caches, and
Nix with `nix-command` and `flakes` enabled. For a first installation, boot NixOS
installation media and keep a local console available. Build on Linux for your
target architecture; cross-compilation isn't part of this walkthrough.

A **flake** is the repository entry point (`flake.nix`); `flake.lock` pins its
inputs, including Nixpkgs. A **host** is one system configuration exported by
that flake. **Home Manager** manages the matching user's packages and settings
as part of the system build here. You don't need a separate Home Manager flake.
See the [Nix flakes introduction](https://nix.dev/concepts/flakes.html) and
[NixOS configuration manual](https://nixos.org/manual/nixos/stable/#sec-configuration-syntax)
for the general concepts.

The commands use `my-host` as an example name. Use your own name consistently in
paths, the flake output, and commands. Run checkout commands from the repository
root. Existing production hosts need their reviewed private input; keep that
workflow separate from this independent installation.

## Choose a configuration

The template starts with no optional features. I recommend keeping it that way
until boot and first access work.

| Goal | Module profile in `mkHost` | What to add later |
| --- | --- | --- |
| Small command-line host or server | `moduleProfiles.server` | Individual services from `modules/server/` and `modules/system-services/` |
| Desktop or laptop | `moduleProfiles.desktop` | Desktop/session, user applications, and development modules |

The module profile makes options available; it doesn't turn them on. My PC and
laptop use Niri with Noctalia; the laptop also enables GNOME. See [customization](customization.md) when you're ready to select
features. Don't import `hosts/common/desktop.nix` wholesale unless you want its
full application selection.

You can use `secretSource = "none"` without a private repository or any encrypted
credentials. Credential-dependent services must stay disabled. If you later
need credentials, [local SOPS](secrets.md#single-repository-setup)
keeps encrypted files in this same checkout. An [optional private input](../../templates/private/README.md)
is a third choice. **No private repository** doesn't mean **no secrets**:
local SOPS needs your own protected decryption identity.

## New machine without secrets

Follow the [NixOS installation manual](https://nixos.org/manual/nixos/stable/#sec-installation)
for installation media, networking, partitioning, encryption, and mounting.
This walkthrough uses manual disk preparation and `nixos-install`.
For a fresh or replacement system disk, [opt-in disko provisioning](storage-provisioning.md)
provides reusable UEFI/ext4 layouts and an explicit whole-disk confirmation barrier.
It does not preserve partitions or change existing hosts during rebuilds.

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
networking, and primary username. The template doesn't choose a bootloader or
network manager for you. For example, a UEFI machine using systemd-boot and wired
DHCP might use the following; only use it if it matches your firmware and mounts:

```nix
boot.loader.systemd-boot.enable = true;
boot.loader.efi.canTouchEfiVariables = true;
networking.useDHCP = true;
time.timeZone = "Etc/UTC";
```

Keep flake commands available after installation by adding
`nix.settings.experimental-features = [ "nix-command" "flakes" ];` to that host
configuration. On installation media, if a command says these features are
disabled, pass `--extra-experimental-features "nix-command flakes"` to Nix for
that command. Keep Git available on the installed system too: add `pkgs` to the
module arguments and `environment.systemPackages = [ pkgs.git ];` if you need
to manage the checkout there.

Set NixOS/Home Manager state versions for this initial installation. These
versions control compatibility defaults, not the installed Nixpkgs release; keep
them stable during ordinary upgrades. Select features in
`hosts/my-host/profile.nix` using [customization](customization.md).
For the first build, leave the optional profile empty.

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

The `host` value also names the ciphertext entry if you later select local or
private secrets. Keep the three existing production outputs unchanged.

**No activation:** stage the new files so the Git flake sees them, then evaluate
and build from the checkout:

```sh
git add hosts/my-host flake/hosts.nix
nix flake check --no-build --no-write-lock-file
nix build --no-link .#nixosConfigurations.my-host.config.system.build.toplevel --no-write-lock-file
```

A successful command returns without configuration errors; the build creates a
system closure in `/nix/store` and `--no-link` avoids a `result` symlink. The
original three production configurations can evaluate with the empty private
input, but their system builds deliberately refuse it.

`--no-build` evaluates checks only. Run `nix flake check --no-write-lock-file` to
execute available checks. A successful build does not test physical boot or SSH.

### 4. Install and verify access

**Changes the mounted target, system profile and boot state.** Check `lsblk -f`
and `findmnt -R /mnt` against your disk plan before running:

```sh
sudo nixos-install --root /mnt --flake .#my-host --no-root-passwd --no-write-lock-file
```

Keep a recoverable checkout on the target. After reboot, test a login from your
client using `ssh -i /protected/client-key YOUR_USER@YOUR_HOST`. Replace the key
path, username, and address with your own values; this is your client private
key, which stays off Git and the Nix store. Then run `id`,
`sudo -v` and `systemctl --failed`. Verify a second login before releasing the
console. `--no-root-passwd` leaves root locked and relies on the user access above.

## Keep it working

Once access works, follow [customization](customization.md) to add
features and [maintenance](maintenance.md) for checks, updates, and
rollback limits. Build before activating. For credentials use the
[SOPS guide](secrets.md); for a build or access failure, see
[troubleshooting](troubleshooting.md).
