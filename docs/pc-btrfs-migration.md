# PC Btrfs migration

This branch prepares a **future clean installation** of `nixos-pc`. Do not
`switch`, `boot`, or activate it on the current ext4 installation. Evaluation and
builds do not migrate data. A previous generation cannot undo formatting.

Disko owns only `disko.devices.disk.nvme`: the 1 TB WD Black SN850X. It creates
GPT, a 2 GiB FAT32 EFI partition at `/boot`, and Btrfs in the remaining space:

| Subvolume | Mount |
| --- | --- |
| `@root` | `/` |
| `@home` | `/home` |
| `@nix` | `/nix` |
| `@games` | `/games` |
| `@var-lib` | `/var/lib` |
| `@snapshots` | `/.snapshots` |

All six use `compress=zstd,noatime`. There is no disk swap; existing zram stays
enabled. TRIM runs weekly; scrub runs monthly once for the shared Btrfs filesystem
through `/`. Scrub detects corruption; a single disk cannot repair damaged data
without another good copy. This does not set up automatic snapshots. Snapshots of
`@root` do not include the other subvolumes and are not external backups.

The HDD's existing ext4 mount at `/home/<user>/drive` remains in the hardware and
private modules. The HDD and secondary SATA SSD have no Disko declarations.
`/games` is a new, initially empty mount; restoring/moving game libraries and
selecting that directory in launchers is a later manual step.

## Required private change and backups

The matching private `disko` branch removes the PC's old `/`, `/efi`, `/boot`, and
`/home` device overrides and sets `disko.devices.disk.nvme.device` to the verified
whole-disk `/dev/disk/by-id/nvme-WD_BLACK_SN850X_1000GB_…` link. It keeps the HDD
UUID override. The public default is deliberately `REPLACE-ME`; do not use that
placeholder or a guessed `/dev/nvme0n1`. The serial belongs in the private module.

Both local branches must be available in the installer. Neither is automatically
pushed. Use the matching private branch explicitly; the usual `.env` remote still
selects its remote branch until you change it. Keep personal URLs out of the
public `flake.lock`.

Before wiping, verify recoverable **external** backups of everything needed from
**every partition on the NVMe**, including other operating systems if present:
`/home`, game libraries, `/etc/ssh`, application databases and container/VM data in
`/var/lib`, any wanted snapshots, and both Git repositories. Stop applications
before their final data backup. Preserve ownership, numeric UID/GID, permissions,
ACLs, xattrs, and symlinks; use application-specific database backups when needed.
Do not put backups on the NVMe being erased.

Back up the existing `/var/lib/sops-nix/key.txt` securely outside either checkout.
The restored identity must decrypt the existing SOPS documents; a generated new
identity cannot. Keep the existing private user settings, SSH host identities,
and state versions. Do not copy a plaintext key or credential into a Git checkout
or any flake input. Have a bootable UEFI NixOS installer and a recovery console.
Disconnecting the HDD and SATA SSD during destructive installation is an extra
way to prevent selecting the wrong disk; reconnect them before normal boot.

## Safe preparation on the current installation

From the public `disko` checkout, with the matching committed private checkout
beside it:

```sh
PRIVATE="git+file://$(realpath ../my-nixos-private)?ref=disko"
just check --no-build --override-input private "$PRIVATE"
just build nixos-pc --override-input private "$PRIVATE"
nix eval --impure .#nixosConfigurations.nixos-pc \
  --override-input private "$PRIVATE" --no-write-lock-file \
  --apply 'import ./lib/test-pc-disko.nix'
nix build --impure --expr 'import ./lib/test-pc-disko-vm.nix {}' --no-link -L
```

The last command formats only a disposable QEMU virtual disk. It tests the layout
and a root replacement preserving data subvolumes; it does not boot the full PC
configuration. These commands do not activate anything on the host.

## Installer preparation: no target disk writes yet

Boot the NixOS installer in **UEFI mode**, connect to the network, and open a
terminal. Replace `/media/backup` with the mounted external backup containing the
prepared public and private Git repositories. These paths require your input.
If needed, enter a tooling shell first:

```sh
nix --extra-experimental-features 'nix-command flakes' shell \
  nixpkgs#git nixpkgs#just nixpkgs#btrfs-progs nixpkgs#rsync
export NIX_CONFIG='experimental-features = nix-command flakes'
test -d /sys/firmware/efi
git clone --branch disko /media/backup/my-nixos /tmp/my-nixos
git clone --branch disko /media/backup/my-nixos-private /tmp/my-nixos-private
cd /tmp/my-nixos
PRIVATE="git+file://$(realpath ../my-nixos-private)?ref=disko"
NVME=$(nix eval --raw \
  .#nixosConfigurations.nixos-pc.config.disko.devices.disk.nvme.device \
  --override-input private "$PRIVATE" --no-write-lock-file)
test -b "$NVME"
lsblk -d -o PATH,MODEL,SIZE,TRAN "$NVME"
lsblk -o PATH,SIZE,FSTYPE,MOUNTPOINTS "$NVME"
readlink -f "$NVME"
just check --no-build --override-input private "$PRIVATE"
just build nixos-pc --override-input private "$PRIVATE"
nix build .#nixosConfigurations.nixos-pc.config.system.build.destroyFormatMount \
  --override-input private "$PRIVATE" --no-write-lock-file --out-link result-disko
nix build .#nixosConfigurations.nixos-pc.config.system.build.mount \
  --override-input private "$PRIVATE" --no-write-lock-file --out-link result-disko-mount
```

Confirm the displayed disk is the **WD Black SN850X 1000GB**, not the HDD or SATA
SSD. Inspect `result-disko/bin/disko-destroy-format-mount` before execution. The
scripts come from this flake's locked Disko input and include the private disk
choice. Building them is safe; executing them writes to disks. Ensure no target
NVMe partition is mounted and `/mnt` is unused before continuing.

## First installation: destructive, future use only

**The next command erases the entire selected NVMe, including all existing
partitions and all data. It cannot preserve the existing ext4 home or games.**
This is the first migration path, after verified backups and disk identification.
Do not run it for a later reinstall that should preserve Btrfs data.

```sh
sudo ./result-disko/bin/disko-destroy-format-mount
findmnt -R /mnt
sudo btrfs subvolume list /mnt
```

Disko prompts before wiping. It creates and mounts the six subvolumes and `/boot`
under `/mnt`. It does not mount the HDD. Check the resulting mount tree before
installing; do not run `nixos-generate-config` over the prepared host modules.

Restore your data into the appropriate mounts. In particular restore the original
SOPS identity **before** installation/first boot. The following assumes the
external backup stores it at the shown path; adjust the source path:

```sh
sudo install -d -m 0700 /mnt/var/lib/sops-nix
sudo install -m 0600 /media/backup/sops-nix/key.txt /mnt/var/lib/sops-nix/key.txt
```

Restore `/home`, game data to `/games`, and required `/var/lib` data using your
verified backup procedure. For example, if your backup has `home/`, `games/`, and
`var-lib/` directories made with rsync:

```sh
sudo rsync -aHAX --numeric-ids /media/backup/home/ /mnt/home/
sudo rsync -aHAX --numeric-ids /media/backup/games/ /mnt/games/
sudo rsync -aHAX --numeric-ids /media/backup/var-lib/ /mnt/var/lib/
```

Keep the HDD mount directory empty while restoring `/home`; exclude its backed-up
contents if the backup followed that mount. Avoid restoring a second copy of
those files onto the NVMe. Restore `/etc/ssh` with its original secure permissions
if preserving SSH host identity. Do not overwrite the new `/boot` with the old
EFI/XBOOTLDR files or restore the old swapfile/fstab. Verify the SOPS key survived
any `/var/lib` restore and that user ownership matches the private configuration.

Install using the prepared public flake and matching private input:

```sh
sudo nixos-install --root /mnt --flake .#nixos-pc \
  --override-input private "$PRIVATE" --no-write-lock-file --no-root-passwd
```

`--no-root-passwd` keeps the configured authentication; verify the restored SOPS
identity and user password source first. Copy both committed repositories to the
installed system if they are not already in your restored data. Reconnect the
other disks if disconnected. Reboot only after checking the mounts, installed
bootloader, backups, identities, and login recovery path. Check login, HDD mount,
SOPS-backed services, zram, and the maintenance timers after the first boot.

## Later reinstall: preserve `@home` and `@games`

This applies **only after Btrfs is installed**. Back up data again. Repeat the
installer preparation above, but **never execute** `result-disko`, a Disko
`destroy`, `format`, `formatMount`, or `destroyFormatMount` command. Formatting the
shared Btrfs filesystem destroys every subvolume. Keep the existing partition
table, FAT filesystem, and Btrfs filesystem.

The simplest reinstall just mounts everything and reruns `nixos-install` above:

```sh
sudo ./result-disko-mount/bin/disko-mount
findmnt -R /mnt
```

That also retains old files in `@root`. For a clean root instead, **before running
the mount command**, replace only `@root`. These commands are destructive to root
files, including `/etc`, but retain `@home`, `@games`, `@nix`, `@var-lib`, and
`@snapshots`. Back up needed `/etc` files and identities first.

```sh
BTRFS="${NVME}-part2"
test -b "$BTRFS"
sudo mkdir -p /mnt-btrfs
sudo mount -o subvolid=5 "$BTRFS" /mnt-btrfs
sudo btrfs subvolume list /mnt-btrfs
# STOP and verify @root is the intended subvolume and has no nested subvolumes.
sudo btrfs subvolume delete /mnt-btrfs/@root
sudo btrfs subvolume create /mnt-btrfs/@root
sudo umount /mnt-btrfs
sudo ./result-disko-mount/bin/disko-mount
findmnt -R /mnt
```

Restore needed `/etc/ssh` files to the new root, verify the retained SOPS identity
at `/mnt/var/lib/sops-nix/key.txt`, then run the same `nixos-install` command.
Preserving `@var-lib` also preserves databases and container state; confirm their
compatibility with the configuration being installed. No partitioning or mkfs is
needed. Keeping subvolumes on one disk does not protect them from disk failure or
an accidental full-disk wipe.
