# Noctalia Greeter

`nixos-pc` and `nixos-lp` use Noctalia Greeter through greetd. The host profiles enable `my.desktop.noctaliaGreeter`, and Niri remains the preferred login session.

The NixOS 26.05 system pins Noctalia Greeter's package and module through the existing `nixpkgs-unstable` input. Shared settings live in `modules/desktops/noctalia-greeter.nix`; the Noctalia Shell appearance preferences are in `config/noctalia/config.toml`.

## Appearance and wallpaper sync

The login view has a minimal, wallpaper-first layout:

- Large time/date in the top-left, with the login panel centered.
- No greeter logo; scheme picker in the top-right and power controls in the bottom-right.
- Niri preselected, with the current login user preselected.
- Bibata cursor and the same US/Russian keyboard layouts as the desktop.

The declarative greeter settings set `appearance.scheme = "Synced"` but deliberately **do not** set `appearance.palette` or an absolute `appearance.wallpaper` path. Pinning the palette or wallpaper would override Noctalia's current colors or per-monitor backgrounds. Instead, Noctalia Shell has `[shell.greeter_sync] auto_sync = true` and syncs the active wallpaper, palette, theme mode, font, and monitor layout to `/var/lib/noctalia-greeter/sync.toml`. The selected scheme becomes *Synced* after the first successful sync.

A narrowly scoped Polkit rule lets the configured local desktop account run only the Greeter 1.5+ `org.noctalia.greeter.sync-appearance` action through the immutable Nix-store helper, restricted to an active local session. It does **not** allow arbitrary root commands or the legacy appearance-sync mode.

The greeter declares `appearance.scheme = "Synced"` so it selects the dynamic Noctalia colors **after** the first successful sync. This cannot generate an initial wallpaper or palette from nothing. A first-time manual sync is required, and a failed sync must be diagnosed rather than replaced by an unchecked wallpaper path.

**One-time setup after the first rebuild:** within your Noctalia desktop, open **Settings → Security → Noctalia Greeter → Sync Now**. You may also use:

```sh
noctalia msg greeter-sync
```

Wait for the sync confirmation. Check the files copied to the greeter (these commands do not expose credentials):

```sh
sudo ls -lah /var/lib/noctalia-greeter/
sudo cat /var/lib/noctalia-greeter/sync.toml
```

If no `sync.toml` or wallpaper file was produced, synchronization did not complete; check the Noctalia notification and `journalctl -b -u greetd`, and confirm the greeter helper/action exist. Then log out to inspect the new wallpaper and palette. Auto-sync handles subsequent wallpaper/theme changes; it is not guaranteed to run on the first installation before any setting changes.

If the background does not update, verify that the greeter helper and Polkit action are present, and check the Noctalia sync status and greetd logs. Do not point `appearance.wallpaper.path` at the live user's home directory: the greeter runs as a separate account and cannot reliably read private home files.

The greeter's supported options let us position the clock, hide the logo and move its auxiliary controls. It does **not** support arbitrary custom UI markup without modifying upstream code.

## GNOME Keyring login prompt

The **Authentication required — The login keyring did not get unlocked** popup is a GNOME Keyring password prompt, not the Noctalia Greeter interface. Styling the greeter does not affect it.

The Niri module enables GNOME Keyring and Seahorse (Passwords and Keys). Greetd's PAM service has `security.pam.services.greetd.enableGnomeKeyring = true`. This can automatically unlock an encrypted **Login** keyring **only when** authentication used the account password and the keyring password matches it. Fingerprint authentication cannot supply the keyring's encryption password.

Unlike the laptop, the PC does not enable fprintd. With password-only authentication, the account password can reach PAM's keyring module and unlock a matching keyring. The laptop's earlier unexpected fingerprint-first behavior was caused by the NixOS per-PAM-service default, not by a Noctalia plugin.

If the prompt still appears after signing in with the account password:

1. First try the **current Linux account password** in the popup. If it fails, try the old account password (if it was changed recently).
2. Open **Passwords and Keys** with `seahorse`, find **Passwords → Login**, then choose **Change Password**. Enter the existing keyring password and change it to the current account login password. This preserves the saved secrets.
3. Log out and sign back in **with your password**, not fingerprint, to verify automatic unlocking.
4. If it persists despite matching passwords, inspect PAM and journal messages:

   ```sh
   grep -n 'pam_gnome_keyring.so' /etc/pam.d/greetd
   journalctl -b -u greetd --no-pager
   journalctl -b | grep -iE 'gkr-pam|gnome-keyring'
   ```

Do **not** delete `~/.local/share/keyrings` or remove the keyring encryption to silence the popup. If the previous keyring password is unknown, existing stored secrets cannot be recovered merely by creating a new keyring. Do not automate a destructive reset.

The laptop keeps `services.fprintd.enable = true`, but explicitly sets `security.pam.services.greetd.fprintAuth = false` (and leaves sudo fingerprint authentication disabled). **This override is required** because NixOS defaults `security.pam.services.<service>.fprintAuth` to `services.fprintd.enable`. Without an explicit override, the greetd PAM conversation enters fingerprint authentication even when the old Ly-specific setting has been removed. This can delay password entry, and fingerprint login cannot supply the account password to the encrypted GNOME Keyring.

Noctalia Greeter and greetd use a sequential PAM conversation: they cannot start fingerprint verification while simultaneously accepting a password as an alternative. Supported choices are password-only (configured here), fingerprint-first followed by a timeout/failure password fallback, or a custom greeter/PAM service to select a method before starting authentication. The laptop intentionally uses password-only so one login can also unlock the keyring.

## Deployment and rollback

Changing the display manager can end your graphical session. Plan the next boot
from a console rather than switching from the active desktop. First select and
build the reviewed input pair using [production deployment](deployment.md).
With its `private_input` variable set, run only on the corresponding host:

```sh
# Non-activating build:
nixos-rebuild build --flake .#nixos-lp --override-input private "$private_input" --no-write-lock-file
# Selects the next boot generation, then reboots; requires operator approval:
sudo nixos-rebuild boot --flake .#nixos-lp --override-input private "$private_input" --no-write-lock-file
sudo reboot
```

Use `nixos-pc` for the PC. For your own adapted host, use its output name and
selected source mode as described in [maintenance](maintenance.md).

At the greeter, select Niri and sign in with the account password. Confirm that the desktop starts, the keyboard works, appearance sync completes, and GNOME Keyring remains unlocked.

If greetd fails, switch to a TTY with Ctrl+Alt+F2/F3. Log in and inspect `journalctl -b -u greetd`. Boot the previous working NixOS generation from systemd-boot, or revert the change and rebuild from the TTY.

Upstream references:

- https://docs.noctalia.dev/greeter/configuration/
- https://docs.noctalia.dev/greeter/sync/
