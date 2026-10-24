# New host template

Follow [the host guide](../../hosts/README.md) to copy this template, add your
machine to the flake, and build it. The guide also has a
[small Niri desktop example](../../hosts/README.md#4-pick-your-features).

- `configuration.nix` holds your account, boot, and networking settings.
- `hardware-configuration.nix` comes from your machine, using `nixos-generate-config`.
- [`profile.nix`](profile.nix) lists the optional features. Uncomment the ones you
  want and fill in the settings noted beside them.

Use `profile = moduleProfiles.all;` and `secretSource = "none"` in your `mkHost`
entry. Optional features start disabled. The imported SSH client module still
configures GitHub/server aliases; review its settings in `profile.nix`.

## Before you install

The account password is locked by `hashedPassword = "!"`, and mutable users are
disabled. An SSH public key lets you authenticate over SSH; it doesn't give you a
password for sudo or the graphical login screen.

- Check your disk UUIDs, mounts, and bootloader against the actual machine.
- Replace the hostname and add your SSH public key to `my.primaryUser.authorizedKeys`.
- Allow the SSH port on the interface or network you'll connect through. The
  template requires an explicit firewall rule and keeps SSH password login off.
- Configure persistent account authentication for console/graphical login if you
  need it, and a working sudo authentication method. With mutable users disabled,
  don't rely on a manual `passwd` change surviving a rebuild. Follow
  [the secrets guide](../../docs/secrets.md) for protected credentials; keep
  passwords and private keys out of Nix source and Git.
- Keep a recovery path: installation media, a working console, or a known-good
  generation for an existing installation. Back up writable data first.

The template checks hostname, SSH key, and firewall settings during evaluation.
You still need to verify that you can boot, log in, and use sudo on the machine.
