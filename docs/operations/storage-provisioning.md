# Provision a fresh system disk

Disko is an opt-in disk preparation tool for a **blank or replacement system
disk**. It is not part of ordinary rebuilds. The three existing host outputs
retain their hardware, filesystem UUIDs, swap, bootloader and service-storage
declarations; they do not import disko or these layouts.

**Apply erases the entire selected disk, including any Windows or data
partitions.** This is not an in-place reinstall or a partition-preservation tool.
The operator must select both a layout and a stable whole-disk path, then type
the exact confirmation. The helper refuses mounted disks, active swap, partitions
and read-only targets. These checks cannot recognize valuable unmounted data.
Disconnect disks you are not provisioning when practical.

## Choose a layout

All layouts use GPT, UEFI/systemd-boot and unencrypted ext4 root. They have no
default disk, no personal identifiers, and no Windows, `/home`, `drive` or server
data partitions. Root uses the remaining disk space.

| Layout argument | Boot partitions | Swap |
| --- | --- | --- |
| `pc` | 512 MiB ESP at `/efi`; 2 GiB XBOOTLDR at `/boot` | 16 GiB `/swapfile`, created by NixOS |
| `laptop` | 512 MiB ESP at `/boot` | 16 GiB `/swapfile`, created by NixOS |
| `server` | 1 GiB ESP at `/boot` | 8 GiB swap partition |

The PC layout preserves its split ESP/XBOOTLDR boot convention, but does not
reproduce its Windows layout. Its fresh ESP is larger than the existing shared
200 MiB ESP. Desktop zram remains a host configuration choice.

The reusable [layout module](../../provisioning/layout.nix) takes explicit `host`
and `device` arguments. A future installer can import it with the pinned disko
module into a **new/adapted host**, retaining its native boot and swapfile
settings. It is not a second host builder. No interactive installer, automatic
hardware selection, encryption migration or private-input interface is added.
Partition operations use children of the selected disk, not global partition-label
links, so a connected old disk with the same GPT labels is not selected instead.

## Before touching a physical disk

Use trusted NixOS installation media booted in UEFI mode, with local console,
network/cache access, Git and Nix flakes enabled. Review firmware/Secure Boot
requirements and ensure the intended replacement disk has room for the boot,
swap, system closure and restored data. Preserve the old disk until recovery is
verified. Do not run provisioning from the installed system being replaced.

- **PC:** back up Windows and its EFI/recovery data before any disk replacement;
  it is not recreated here. Preserve the separate `/home` SSD and `drive` HDD.
- **Laptop:** `drive` is on the **same physical disk as root**, not a separate
  disk. Back it up before replacement. The fresh layout omits that partition;
  restore its data to reviewed storage and adapt its mount declaration separately.
- **Server:** back up `/srv/appdata` (including Syncthing), `/srv/compose`,
  `/srv/backups`, Docker volumes and other used root-resident service data.
  `/srv/storage` is on a separate disk; leave it untouched. Its existing MBR/logical
  partition layout is not converted. Coordinate gateway downtime with both clients.
- Verify recovery copies by restoring samples into protected scratch storage.
  Keep original SOPS age identities, encrypted documents, SSH client identities
  and mutable application data outside the disk being erased. Preserve reviewed
  source revisions and a bootable rescue medium. A generation rollback cannot
  undo partitioning or restore data.

There is no LUKS/key-generation step: this matches the inventoried unencrypted
storage. New encryption policy needs separate review. Never put private keys,
plaintext credentials or decrypted secrets in either flake or the Nix store.
Existing-host restoration requires the original root-owned mode-0400/0600 age
identity; see [deployment and recovery](deployment.md#restore-an-existing-host).

## Preview and explicitly apply

Run from the public repository checkout, after reviewing the inventory below.
Replace the synthetic disk path with the **replacement** disk's actual `by-id`
link. The examples intentionally supply no real host disk selector:

```sh
host=pc  # or laptop or server; this selects a layout, not an existing host output
device=/dev/disk/by-id/YOUR-REPLACEMENT-WHOLE-DISK
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS
readlink -e "$device"
provisioner=$(nix build .#provision-disk --no-link --print-out-paths --no-write-lock-file)
"$provisioner/bin/provision-disk" preview "$host" "$device"
```

Preview builds and prints the disko script path; it does not execute it. Review
that generated script and verify the target model, capacity and partition plan.
Only after backups and a separate physical provisioning decision:

```sh
# DESTRUCTIVE: erases the entire selected disk and mounts the fresh root at /mnt.
sudo "$provisioner/bin/provision-disk" apply "$host" "$device"
# Type exactly: ERASE <the chosen host argument> <the exact by-id path>
```

The helper uses the pinned disko release and repository Nixpkgs. It performs only
partitioning, formatting and mounting under `/mnt`; it does not install a system,
restore data, provision identities, enroll Tailscale or activate any host.

Afterward inspect `lsblk -f` and `findmnt -R /mnt`. Generate hardware declarations
for the **new target**, as in [installation](installation.md#1-prepare-and-copy),
and review the new filesystem/swap UUIDs, boot mount points and firmware support.
Do not blindly install an existing output: it still references its old UUIDs and
data mounts. Adapt a new host or separately review the replacement host's hardware
declarations before installation. Desktop hardware scanning cannot discover a
swapfile that does not exist yet; retain the layout's native 16 GiB `swapDevices`
declaration. Set UEFI-variable access deliberately for the installation environment.

Reconnect preserved data disks, verify their identities, review mount dependencies
and restore data before enabling dependent services. Retain the original account,
UID and ownership where restoring an existing installation. Use the guarded
[production installer](deployment.md#restore-an-existing-host) when restoring one
of the existing private-backed hosts. Keep console/recovery access through boot,
a second login, mount/swap checks and application/VPN acceptance.

## Inventory before implementation

Observed 2026-10-20: PC read locally; laptop and server from operator-supplied
`lsblk`, `findmnt`, `swapon`, `by-id` and firmware output. All booted in UEFI mode.
Mounted filesystem UUIDs match their tracked hardware declarations. These are
observations, **not replacement-device defaults**; verify them again on site.

| Host | Actual system disk and boot/root | Data outside the fresh layout | Actual swap |
| --- | --- | --- | --- |
| PC | 1 TB WD Black SN850X NVMe; `p1` 200 MiB vfat `/efi`, `p6` 2 GiB vfat XBOOTLDR `/boot`, `p7` ext4 `/`; also MSR, Windows/NTFS and recovery partitions | 120 GB Crucial SSD `/home`; 1 TB Toshiba HDD `drive`; all Windows partitions | 16 GiB swapfile plus zram |
| Laptop | 512 GB Toshiba NVMe; `p1` 512 MiB vfat `/boot`, `p6` ext4 `/` | `p2` ext4 `drive` on that **same NVMe** | 16 GiB swapfile plus zram |
| Server | 256 GB Samsung PM951 NVMe; `p1` 1 GiB vfat `/boot`, `p2` 8 GiB swap, `p3` ext4 `/` | 1 TB external disk, MBR extended/logical `sda5`, ext4 `/srv/storage`; other checked `/srv/*` paths on root | 8 GiB partition |

Stable whole-disk links were present under `/dev/disk/by-id` for each physical
disk (NVMe model/EUI links, ATA model/WWN links, and a USB alias for server data).
Aliases can name the same disk. Select the actual replacement by inspecting its
resolved device and capacity; never derive it from `pc`, `laptop`, `server`, or
an observed `/dev/sdX`/`nvmeX` enumeration. Current UUID declarations remain in
[PC](../../hosts/pc/hardware-configuration.nix),
[laptop](../../hosts/laptop/hardware-configuration.nix),
[server](../../hosts/server/hardware-configuration.nix) and
[server storage](../../hosts/server/profile.nix).

## Disposable verification

These registered checks format **VM disks only** and boot their installed UEFI
systems. They inspect GPT/filesystems, generated hardware declarations, mounts,
boot files and active swap. A connected VM disk with a duplicate root partition
label retains its complete checksum. Desktop
swapfiles are reduced to 64 MiB only in the tests; evaluation checks retain the
production 16 GiB declarations.

```sh
nix build --no-link --no-write-lock-file \
  .#checks.x86_64-linux.provisioning-guard \
  .#checks.x86_64-linux.provisioning-layouts \
  .#checks.x86_64-linux.provisioning-pc \
  .#checks.x86_64-linux.provisioning-laptop \
  .#checks.x86_64-linux.provisioning-server
```

Guard tests use fake disk metadata to check wrong/missing selectors, mounted/swap
and read-only disks, privilege, preview and confirmation refusal without touching
physical disks. VM tests need Linux virtualization support. They do not establish
real firmware behavior, backups, restored data, physical installation or encryption
support. Routine host checks/builds remain in [deployment](deployment.md).
