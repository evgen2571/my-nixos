# Noctalia Greeter

`nixos-pc` and `nixos-lp` use Noctalia Greeter through greetd. The host profiles enable `my.desktop.noctaliaGreeter`, and Niri remains the preferred login session.

The NixOS 26.05 system pins Noctalia Greeter's package and module through the existing `nixpkgs-unstable` input. Shared settings live in `modules/desktops/noctalia-greeter.nix`; the Noctalia Shell appearance preferences are in `config/noctalia/config.toml`.

## Appearance and wallpaper sync

The login view has a minimal, wallpaper-first layout:

- Large time/date in the top-left, with the login panel centered.
- No greeter logo; scheme picker in the top-right and power controls in the bottom-right.
- Niri preselected, with the current login user preselected.
- Bibata cursor and the same US/Russian keyboard layouts as the desktop.

The declarative greeter settings deliberately **do not** set `appearance.scheme`, `appearance.palette`, or an absolute `appearance.wallpaper` path. These would override Noctalia's current theme or per-monitor wallpapers. Instead, Noctalia Shell has `[shell.greeter_sync] auto_sync = true` and syncs the active wallpaper, palette, theme mode, font, and monitor layout to `/var/lib/noctalia-greeter/sync.toml`. The selected scheme becomes *Synced* after the first successful sync.

A narrowly scoped Polkit rule lets the configured local desktop account run only the Greeter 1.5+ `org.noctalia.greeter.sync-appearance` action through the immutable Nix-store helper, restricted to an active local session. It does **not** allow arbitrary root commands or the legacy appearance-sync mode.

**One-time setup after the first rebuild:** within your Noctalia desktop, open **Settings → Security → Noctalia Greeter → Sync Now**. You may also use:

```sh
noctalia msg greeter-sync
```

Wait for the sync confirmation, then log out to inspect the new wallpaper and palette. Auto-sync handles subsequent wallpaper/theme changes; it is not guaranteed to run on the first installation before any setting changes.

If the background does not update, verify that the greeter helper and Polkit action are present, and check the Noctalia sync status and greetd logs. Do not point `appearance.wallpaper.path` at the live user's home directory: the greeter runs as a separate account and cannot reliably read private home files.

The greeter's supported options let us position the clock, hide the logo and move its auxiliary controls. It does **not** support arbitrary custom UI markup without modifying upstream code.

## GNOME Keyring login prompt

The **Authentication required — The login keyring did not get unlocked** popup is a GNOME Keyring password prompt, not the Noctalia Greeter interface. Styling the greeter does not affect it.

The Niri module enables GNOME Keyring and Seahorse (Passwords and Keys). Greetd's PAM service has `security.pam.services.greetd.enableGnomeKeyring = true`. This can automatically unlock an encrypted **Login** keyring **only when** authentication used the account password and the keyring password matches it. Fingerprint authentication cannot supply the keyring's encryption password.

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

The laptop keeps `services.fprintd.enable = true`, but greetd fingerprint PAM remains disabled: `pam_fprintd` can block password entry in a serial PAM conversation, and a fingerprint login would not unlock the keyring anyway.

## Deployment and rollback

Avoid applying display-manager changes via `nixos-rebuild switch` from the active graphical session. From the root of this repository on the corresponding host:

```sh
nixos-rebuild build --flake .#nixos-lp # or .#nixos-pc
sudo nixos-rebuild boot --flake .#nixos-lp # or .#nixos-pc
sudo reboot
```

At the greeter, select Niri and sign in with the account password. Confirm that the desktop starts, the keyboard works, appearance sync completes, and GNOME Keyring remains unlocked.

If greetd fails, switch to a TTY with Ctrl+Alt+F2/F3. Log in and inspect `journalctl -b -u greetd`. Boot the previous working NixOS generation from systemd-boot, or revert the change and rebuild from the TTY.

Upstream references:

- https://docs.noctalia.dev/greeter/configuration/
- https://docs.noctalia.dev/greeter/sync/
