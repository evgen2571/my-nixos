# Login screen and keyring

PC and laptop use Noctalia Greeter through greetd, with Niri preselected. The
[greeter module](../../modules/desktop/noctalia-greeter.nixos.nix) owns login layout
and PAM integration. [Noctalia Shell](../apps/noctalia.md) owns desktop appearance.

## Sync appearance

After the first rebuild, open Noctalia **Settings → Security → Noctalia Greeter →
Sync Now**, or run from the desktop:

```sh
noctalia msg greeter-sync
```

Wait for confirmation, then check the copied appearance files:

```sh
sudo ls -lah /var/lib/noctalia-greeter/
sudo cat /var/lib/noctalia-greeter/sync.toml
```

Log out to check the result. Later wallpaper/theme changes sync automatically.
First-install auto-sync is not guaranteed before a setting changes.

The greeter selects the `Synced` scheme. Noctalia copies wallpaper, palette,
theme mode, font and monitor layout into `/var/lib/noctalia-greeter/`. Nix leaves
palette and wallpaper paths unset so they do not override the synced appearance.
A missing `sync.toml` means sync did not complete. Check the desktop notification,
helper/Polkit action and `journalctl -b -u greetd`.

The Polkit permission applies only to the immutable appearance helper for the
active local desktop account. It does not grant arbitrary commands. Do not point
the greeter at a wallpaper inside a private home directory; its separate account
may be unable to read it. Arbitrary greeter UI markup requires upstream changes.

## Unlock GNOME Keyring

"The login keyring did not get unlocked" comes from GNOME Keyring. It can unlock
at login when PAM receives the account password and that password matches the
Login keyring password. Fingerprint authentication cannot supply it.

1. Try the current account password in the prompt, then the previous password if
   it recently changed.
2. Open `seahorse` (Passwords and Keys). Under **Passwords → Login → Change
   Password**, use the existing keyring password and set it to the account password.
   This preserves saved secrets.
3. Log out and sign in with the account password.
4. If it persists, inspect PAM and logs:

   ```sh
   rg -n 'pam_gnome_keyring.so' /etc/pam.d/greetd
   journalctl -b -u greetd --no-pager
   journalctl -b | rg -i 'gkr-pam|gnome-keyring'
   ```

Never delete `~/.local/share/keyrings` or remove encryption to silence the prompt.
A new keyring cannot recover secrets encrypted with an unknown old password.

The laptop enables fprintd but explicitly disables greetd fingerprint
authentication and sudo fingerprint authentication. Keep
`security.pam.services.greetd.fprintAuth = false`: NixOS otherwise inherits
fprintd's enabled state. Greeter/PAM authentication is sequential; it cannot
accept a password while fingerprint verification runs. Password-only login lets
one authentication unlock the keyring.

## Deploy and recover

Build first with the reviewed private input from [deployment](deployment.md).
For an approved display-manager update, prefer a next-boot deployment rather than
switching from the active graphical session. With `private_input` set as in that
guide, choose the matching host:

```sh
target=nixos-lp # or nixos-pc
nix build --no-link ".#nixosConfigurations.$target.config.system.build.toplevel" \
  --override-input private "$private_input" --no-write-lock-file
# Changes the next boot generation:
sudo nixos-rebuild boot --flake ".#$target" \
  --override-input private "$private_input" --no-write-lock-file
sudo reboot
```

For an independently adapted host, use its output name and selected source mode
from [maintenance](maintenance.md).

Check password login, keyboard, Niri startup, appearance sync and keyring unlock.
If login fails, use Ctrl+Alt+F2/F3 for a TTY and inspect
`journalctl -b -u greetd`. Boot the known-good generation from systemd-boot or
restore its reviewed source pair from the TTY.

Upstream: [configuration](https://docs.noctalia.dev/greeter/configuration/),
[appearance sync](https://docs.noctalia.dev/greeter/sync/).
