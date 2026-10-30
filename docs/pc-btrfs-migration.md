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
`/games` is a new, initially empty mount. Only the PC enables the home/game
layout below; laptop and server storage stays unchanged.

```text
/home/<user>/
├── dev/                         ordinary directory in @home
├── games -> /games
├── downloads/
├── pictures/
│   └── wallpapers/              recursive links from the wallpapers flake
├── .config/
├── .local/share/
│   ├── Steam/steamapps -> /games/steam/steamapps
│   └── PrismLauncher/instances -> /games/minecraft/instances
└── .ssh/
/games/
├── steam/steamapps/              all Steam games, manifests, Proton prefixes
└── minecraft/instances/         Minecraft worlds, mods and resource packs
```

Home Manager sets XDG downloads/pictures/projects to lowercase directories.
Unused XDG entries point to the home itself (the XDG way to disable them), so it
does not create Documents, Desktop, Music, Public, Templates or Videos. It creates
`dev` as a directory, never a link or subvolume. Existing uppercase directories
are not removed or renamed by activation.

The `game-storage` service applies a private systemd-tmpfiles rule file only after
`/games` is mounted, checks for conflicting files/symlinks, and runs before Home
Manager. Global tmpfiles runs cannot create these directories on an unmounted
filesystem. Directory creation is idempotent and uses the configured primary
user/group; it never copies or deletes installations.

Steam 1.0.0.85's packaged `bin_steam.sh` defaults to
`$XDG_DATA_HOME/Steam` and resolves an existing `~/.steam/steam` first. Its normal
`~/.steam/{steam,root}` links therefore reach the same `steamapps` link without a
loop. Keep the client, config and userdata in home; no Steam VDF files are managed.
A restored real `~/.steam/steam`, custom root link or legacy `~/Steam` must be
reconciled manually before activation.

Prism Launcher 11.1.1 uses the normal Qt data directory
`~/.local/share/PrismLauncher`, changes its working directory there and defaults
`InstanceDir` to `instances`. The Nixpkgs wrapper does not override it. A restored
custom `InstanceDir` must be reset after its contents are restored; activation
rejects other paths instead of rewriting launcher settings. Do not launch with
`--dir` or `PRISMLAUNCHER_DATA_DIR` overrides if you want this layout.

Noctalia and the existing wallpaper flake module share `~/pictures/wallpapers`.
The private HDD wallpaper override is removed for both desktops; dynamic colors,
templates and wallpaper automation stay enabled. No second wallpaper declaration
or download script is added.

## Required private change and backups

The matching private `disko` branch removes the PC's old `/`, `/efi`, `/boot`, and
`/home` device overrides and sets `disko.devices.disk.nvme.device` to the verified
whole-disk `/dev/disk/by-id/nvme-WD_BLACK_SN850X_1000GB_…` link. It keeps the HDD
UUID override and explicitly preserves the existing PC UID (1000, group `users`/100).
The by-id link was checked against the current WD model and whole disk during
preparation; verify it again in the installer. The public default is deliberately `REPLACE-ME`; do not use that
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
set -euo pipefail
test "$(git -C ../my-nixos-private branch --show-current)" = disko
test -z "$(git -C ../my-nixos-private status --porcelain)"
PRIVATE_REV=$(git -C ../my-nixos-private rev-parse HEAD)
PRIVATE="git+file://$(realpath ../my-nixos-private)?rev=$PRIVATE_REV"
just check --no-build --override-input private "$PRIVATE"
just build nixos-pc --override-input private "$PRIVATE"
```

These commands evaluate and build the configuration without activating it. They
do not verify boot, runtime behavior, or the installation procedure below.

## Installer preparation: no target disk writes yet

Boot the NixOS installer in **UEFI mode**, connect to the network, and open a
terminal. Replace `/media/backup` with the mounted external backup containing the
prepared public and private Git repositories. These paths require your input.
If needed, enter a tooling shell first:

```sh
nix --extra-experimental-features 'nix-command flakes' shell \
  nixpkgs#git nixpkgs#just nixpkgs#btrfs-progs nixpkgs#rsync nixpkgs#mkpasswd
export NIX_CONFIG='experimental-features = nix-command flakes'
set -euo pipefail
test -d /sys/firmware/efi || { echo 'Stop: installer is not booted in UEFI mode' >&2; exit 1; }
git clone --branch disko /media/backup/my-nixos /tmp/my-nixos
git clone --branch disko /media/backup/my-nixos-private /tmp/my-nixos-private
cd /tmp/my-nixos
test "$(git -C ../my-nixos-private branch --show-current)" = disko
test -z "$(git -C ../my-nixos-private status --porcelain)"
PRIVATE_REV=$(git -C ../my-nixos-private rev-parse HEAD)
PRIVATE="git+file://$(realpath ../my-nixos-private)?rev=$PRIVATE_REV"
NVME=$(nix eval --raw \
  .#nixosConfigurations.nixos-pc.config.disko.devices.disk.nvme.device \
  --override-input private "$PRIVATE" --no-write-lock-file)
test -b "$NVME" || { echo 'Stop: verified NVMe link is unavailable' >&2; exit 1; }
lsblk -d -o PATH,MODEL,SIZE,TRAN "$NVME"
lsblk -o PATH,SIZE,FSTYPE,MOUNTPOINTS "$NVME"
readlink -f "$NVME"
just check --no-build --override-input private "$PRIVATE"
just build nixos-pc --override-input private "$PRIVATE" --out-link result-pc
nix build .#nixosConfigurations.nixos-pc.config.system.build.nixos-install \
  --override-input private "$PRIVATE" --no-write-lock-file --out-link result-installer
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

## Restore order and home conflicts (installer only)

Keep applications closed until restoration and the first Home Manager activation
are complete. Preserve numeric ownership, permissions, ACLs, xattrs and symlinks.
Record the old UID/GID before backup; the PC private module pins its existing UID
and retains the standard `users` group. Back up actual project contents separately:
an archive preserving `~/dev` only preserves its old symlink, not the projects.
Do not copy or modify the HDD during these steps; use verified external backups.

1. Verify all six target mounts with `findmnt -R /mnt`. Restore required `/var/lib`
   data first, excluding obsolete swap/fstab/boot state. Restore SSH host keys into
   `/mnt/etc/ssh` with their original secure permissions. Do not restore the old
   EFI/XBOOTLDR tree over `/mnt/boot`.
2. Restore home while excluding the old dev/games links, HDD mount, both wallpaper
   collection locations, Steam's `steamapps` and Prism's `instances`. For example,
   with a backup rooted at `home/<user>`:

   ```sh
   USER_NAME=$(nix eval --raw .#nixosConfigurations.nixos-pc.config.my.primaryUser.name \
     --override-input private "$PRIVATE" --no-write-lock-file)
   HOME_BACKUP="/media/backup/home/$USER_NAME"
   TARGET_HOME="/mnt/home/$USER_NAME"
   sudo rsync -aHAX --numeric-ids \
     --exclude="/$USER_NAME/drive" --exclude="/$USER_NAME/dev" \
     --exclude="/$USER_NAME/games" \
     --exclude="/$USER_NAME/.local/share/Steam/steamapps" \
     --exclude="/$USER_NAME/.local/share/Steam/config/libraryfolders.vdf" \
     --exclude="/$USER_NAME/.local/share/PrismLauncher/instances" \
     --exclude="/$USER_NAME/Pictures/Wallpapers" \
     --exclude="/$USER_NAME/pictures/wallpapers" \
     /media/backup/home/ /mnt/home/
   ```

   On a preserving reinstall, do not rsync home over existing managed links.
   Restore only missing files from backup after inspecting their targets.
3. Restore game contents directly to the mounted `/games` destinations, **before**
   creating the home links. These are examples: check backup paths first. Copy the
   whole Steam `steamapps` directory, including `appmanifest_*.acf`, `common`,
   `compatdata` and `shadercache`. Wuthering Waves remains there with other games.
   If Prism had a custom `InstanceDir`, restore from that actual backed-up path.

   ```sh
   USER_UID=$(stat -c %u "$HOME_BACKUP")
   USER_GID=$(stat -c %g "$HOME_BACKUP")
   # Confirm these match the recorded IDs and private user configuration.
   sudo install -d -o "$USER_UID" -g "$USER_GID" \
     "$TARGET_HOME/dev" /mnt/games/steam/steamapps /mnt/games/minecraft/instances
   sudo rsync -aHAX --numeric-ids /media/backup/projects/ "$TARGET_HOME/dev/"
   sudo rsync -aHAX --numeric-ids --exclude=/libraryfolders.vdf \
     "$HOME_BACKUP/.local/share/Steam/steamapps/" \
     /mnt/games/steam/steamapps/
   sudo rsync -aHAX --numeric-ids "$HOME_BACKUP/.local/share/PrismLauncher/instances/" \
     /mnt/games/minecraft/instances/
   ```

   Keep the old `libraryfolders.vdf` files in the backup, but exclude them from
   a fresh restoration as above. The current metadata also lists an HDD library;
   letting Steam rebuild its default-library metadata avoids carrying that entry
   into the clean installation. Games from other libraries need their own verified
   external backups and deliberate restoration into the same target `steamapps`;
   resolve duplicate manifests/filenames manually. This does not modify the HDD.

   No automatic moves or deletion occur. Keep backups until both applications
   detect and launch their restored installations. If backup game directories
   already have the new canonical layout, restore that layout instead.
4. Inspect restored `~/.steam/{steam,root}`, `~/Steam`, the normal Steam and Prism
   data directories, and `prismlauncher.cfg`. Compatibility links may target only
   the normal home Steam directory; preserve/reconcile legacy real directories
   manually. With Prism closed, reset a custom `InstanceDir` to `instances` in the
   **restored target** config, or remove that one entry to use its default. Keep
   other settings. Nothing in activation edits this file.
5. Review uppercase Downloads/Pictures and lowercase directories individually.
   Compare files before copying them to lowercase paths; resolve name collisions
   without overwriting either copy. Do not restore old wallpapers over the
   flake collection. Keep unique personal wallpapers separately, for example in
   `pictures/wallpapers-personal`, and retain the external backup. The private
   avatar still refers to `Pictures/Avatars`; preserve that path unless you also
   update your avatar setting. Do not delete uppercase directories automatically.
6. Leave `~/games`, `Steam/steamapps`, and `PrismLauncher/instances` absent in the
   target home, or retain only links resolving to their exact new destinations.
   Leave `pictures/wallpapers` absent or containing only existing Home Manager
   links. Home Manager will create the links on first boot, and refuse conflicts
   before its write boundary even though general HM backups are enabled. It also
   refuses a symlink, mount or Btrfs subvolume at `dev`. Never bypass this with
   `force`, a backup overwrite option, or automatic data relocation.

Restore the original SOPS identity **after** other `/var/lib` restoration, before
installation. A newly generated identity cannot decrypt the existing documents:

```sh
sudo install -d -m 0700 /mnt/var/lib/sops-nix
sudo install -m 0600 /media/backup/sops-nix/key.txt /mnt/var/lib/sops-nix/key.txt
```

`/var/lib` is marked `neededForBoot`, so the age key is available before SOPS's
`neededForUsers` password activation. Preserve all existing SOPS and SSH identities
and both state versions; never put identity files in either Git checkout.

## Independent recovery login and installation

The PC root console password comes from `/var/lib/nixos/recovery-password`, a
protected runtime hash file independent of SOPS. Provision it before installing,
or securely restore your existing recovery hash on subsequent reinstalls. It is
read on every activation because users are immutable; a plain `passwd root`
change alone will not persist. Choose a strong recovery password and keep it in
your password manager. This enables console recovery, not an SSH root service.

If the recovery hash was retained or restored, skip the generation/chown/chmod
commands below and start with the nonempty-file check. For a new hash, this prompts
without putting the password or hash in shell history,
Git, a flake input or the Nix store (do not run it with shell tracing):

```sh
sudo mkdir -p /mnt/var/lib/nixos
MKPASSWD=$(command -v mkpasswd)
sudo sh -c 'umask 077; "$1" -m yescrypt > /mnt/var/lib/nixos/recovery-password' sh "$MKPASSWD"
sudo chown root:root /mnt/var/lib/nixos/recovery-password
sudo chmod 0600 /mnt/var/lib/nixos/recovery-password
sudo test -s /mnt/var/lib/nixos/recovery-password || { echo 'Stop: recovery hash is missing or empty' >&2; exit 1; }
SYSTEM=$(readlink -f result-pc)
sudo "$SYSTEM/bin/deployment-preflight" /mnt
```

The preflight decrypts only to `/dev/null` and refuses an absent/unsafe age identity
or one that cannot decrypt the selected private ciphertext. Do not bypass it.
Run all installer blocks in the same fail-fast shell initialized above; stop
on any failed command. Do not continue after a failed safety check.
Check recovery file ownership/mode without displaying its contents. Back it up
securely outside the repositories alongside the age identity.

Install the **already built** PC closure using this configuration's patched
installer, which repeats the target-root SOPS preflight before selecting a system
generation. This avoids re-resolving a private branch as root or accidentally
using the installer's unpatched `nixos-install`:

```sh
# Copy the closure first: --system alone would leave the pre-profile gate absent.
sudo nix --extra-experimental-features nix-command copy --to 'local?root=/mnt' "$SYSTEM"
sudo test -x "/mnt$SYSTEM/bin/deployment-preflight" || { echo 'Stop: target preflight is unavailable' >&2; exit 1; }
sudo ./result-installer/bin/nixos-install --root /mnt \
  --system "$SYSTEM" --no-root-passwd
```

`--no-root-passwd` is intentional only after the independent recovery hash is
provisioned; it does not unlock an unconfigured account. Installation activates
the **target** under `/mnt`, so check all restored conflicts beforehand. It must
never be run from the current ext4 installation as a migration shortcut.

Before reboot, validate root's installed hash against the protected recovery
file without printing either value. The following activates only the installed
target and runs the comparison there:

```sh
sudo nixos-enter --root /mnt --command \
  'test "$(getent shadow root | cut -d: -f2)" = "$(cat /var/lib/nixos/recovery-password)"'
sudo test -s /mnt/run/secrets-for-users/user-password
findmnt -R /mnt
sudo ls /mnt/boot/EFI/systemd /mnt/boot/loader/entries
```

Copy both committed checkouts into the new `~/dev` if needed. Set the installed
checkout's local `.env` `MY_NIXOS_PRIVATE` to the matching local private checkout,
not the former remote `main` input. Review both `disko` commits explicitly on
future rebuilds until they are intentionally integrated. Keep personal URLs out
of the public lock. Reconnect the other disks before normal boot so their
unchanged mounts can succeed.

## First boot verification

Log in on a console as root with the recovery password, then test normal user
login. Keep the UEFI installer available. If SOPS fails, use root to inspect the
mount and protected key permissions; restore the original identity from backup.
Do not generate a replacement identity or reset encrypted passwords blindly.
The installer remains the fallback if the system cannot reach a console.

As the primary user:

```sh
findmnt -T "$HOME/dev"
test -d "$HOME/dev" && test ! -L "$HOME/dev"
! btrfs subvolume show "$HOME/dev"
readlink -f "$HOME/games"
readlink -f "$HOME/.local/share/Steam/steamapps"
readlink -f "$HOME/.local/share/PrismLauncher/instances"
xdg-user-dir DOWNLOAD
xdg-user-dir PICTURES
systemctl status game-storage "home-manager-$USER"
systemctl status sops-install-secrets
swapon --show
systemctl list-timers 'fstrim*' 'btrfs-scrub*'
```

Expect the dev filesystem to be `@home`, the three link destinations to be
`/games`, `/games/steam/steamapps`, `/games/minecraft/instances`, and XDG paths to be
lowercase. Confirm `~/pictures/wallpapers` contains the flake collection and
Noctalia sees it, changes wallpapers and regenerates colors. If restored Noctalia
state in `~/.local/state/noctalia/settings.toml` contains the old wallpaper path,
remove/reset only that saved wallpaper override with Noctalia closed; retain all
other GUI settings. Declarative configuration does not erase unrelated state.

Launch Steam and check Settings → Storage: the default home library should list
the restored games while its `steamapps` resolves to `/games/steam/steamapps`.
Steam may display the home client path; that is expected. Keep manifests with the
games and use Steam's verify/discover action if necessary. Check
`~/.steam/{steam,root}/steamapps` resolves to the same destination after Steam
initializes its compatibility links. Keep any old custom-library VDF entries
under review; this configuration does not rewrite them.

In Prism, check Settings → Launcher → Folders → Instances is `instances` (or the
canonical absolute target) and that restored instances appear. Confirm an
instance's `.minecraft/saves`, mods and resourcepacks resolve under `/games`.
Test one game from each launcher before considering the restoration complete.
Also verify the unchanged HDD mount and SOPS-backed services. Do not remove
external backups merely because a build or VM test passed.

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
test -b "$BTRFS" || { echo 'Stop: Btrfs partition link is unavailable' >&2; exit 1; }
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
at `/mnt/var/lib/sops-nix/key.txt`. Verify or restore the protected recovery hash
and inspect the home conflicts above,
then run the same patched installer with the newly built `SYSTEM`. Do not restore
home or game backups over the retained links.
Preserving `@var-lib` also preserves databases and container state; confirm their
compatibility with the configuration being installed. No partitioning or mkfs is
needed. Keeping subvolumes on one disk does not protect them from disk failure or
an accidental full-disk wipe.

## Preparation validation (2026-10-29)

Executed without activating the running installation:

- All three production hosts evaluated with the matching committed private input;
  full `nixos-pc` build passed. Disko and PC Home Manager assertions passed.
- Disposable Disko VM passed partition/subvolume/compression checks, root-only
  replacement retaining data, UEFI boot, deliberate SOPS identity failure, root
  PAM authentication (and wrong-password rejection), game ownership/links,
  repeated Home Manager activation with wallpapers, idempotent initialization,
  symlink-conflict rejection and global tmpfiles safety with `/games` unmounted.
- Seven disposable home-preflight tests, three Noctalia cleanup tests, the six
  Noctalia configuration fixtures, shell syntax and ShellCheck passed.
- Built the patched installer and both Disko scripts without executing them on
  physical disks. The built home links resolve to the three expected destinations.
- Laptop/server mounts, user-ID settings and state versions match the baseline.
  Laptop deliberately adopts the shared lowercase wallpaper default; with the
  original private revision, the server closure is identical to the baseline.
  Selecting a newer private source revision changes its source-dependent closure.

Reviewed: packaged Steam/Prism source and current path settings, private disk ID
against the current whole NVMe, installer preflight order, and backup/restore
commands. The guide's shell blocks were parsed, not executed.

Not tested: full PC graphical/UEFI boot on physical hardware, live SOPS decryption
with the real identity, the entire physical `nixos-install` sequence, or launching
Steam/Minecraft/Wuthering Waves and generating colors in the running desktop.
Those checks belong to the future installation and first boot above.
