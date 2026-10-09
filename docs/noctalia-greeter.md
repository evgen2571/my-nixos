# Noctalia Greeter

Both `nixos-pc` and `nixos-lp` use the Noctalia Greeter through greetd. Niri is the preferred login session; other installed sessions remain selectable.

The system follows nixpkgs 26.05 and imports the greeter's NixOS module and package from the existing pinned `nixpkgs-unstable` input. No additional flake input or lock update is required. Configure the shared greeter in `modules/desktops/noctalia-greeter.nix`, and select it from each host profile.

## Deployment

Before changing the login manager, retain a TTY recovery path. **Do not apply the change with `nixos-rebuild switch` while depending on the active graphical session.** From the repository root, on the corresponding host:

```sh
nixos-rebuild build --flake .#nixos-lp # or .#nixos-pc
sudo nixos-rebuild boot --flake .#nixos-lp # or .#nixos-pc
sudo reboot
```

At the greeter select Niri and sign in with the account password. Confirm that Niri starts, the cursor and keyboard work, and there is no duplicate display manager. When functional, test the other sessions if needed.

If the greeter is unusable, switch to a text console (Ctrl+Alt+F2/F3), sign in, and select an earlier working NixOS generation from systemd-boot at reboot. You can also roll back through the previous system profile, or revert the greeter change and rebuild from a TTY.

## Keyring and fingerprint authentication

The greetd PAM service enables GNOME Keyring integration. Signing in with the account password can unlock the `login` keyring if its password matches the account password. A fingerprint does **not** provide the password necessary to unlock an encrypted keyring.

The laptop retains `services.fprintd.enable = true`, but this migration deliberately removes `security.pam.services.ly.fprintAuth` and does not automatically enable `greetd.fprintAuth`. With sequential PAM fingerprint authentication, a fingerprint scan can block password entry until timeout. After testing password login, fingerprint functionality can be evaluated separately; the greeter offers `auth.allow_empty_password` for triggering PAM authentication with an empty submission, but the configured PAM stack determines behavior. Do not assume both login methods will work simultaneously.

To diagnose login or keyring problems:

```sh
journalctl -b -u greetd --no-pager
journalctl -b | grep -iE 'gkr-pam|gnome-keyring'
```

Noctalia Shell's optional **Settings → Security → Noctalia Greeter → Sync Now** can transfer wallpaper and palette to the greeter using authenticated Polkit. Passwordless sync is not enabled.

Upstream reference: https://docs.noctalia.dev/greeter/
