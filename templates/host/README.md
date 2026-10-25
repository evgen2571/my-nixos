# Host template

Follow [the installation guide](../../hosts/README.md) to copy this template,
configure your machine, and try a build.

- `configuration.nix`: account, password file, bootloader, networking, state versions.
- `hardware-configuration.nix`: copy or generate this on your machine.
- `profile.nix`: optional features. Uncomment the ones you want.

The template keeps immutable users and reads the login password hash from
`/var/lib/my-nixos/login-password`. Create that protected file before activation
as shown in the guide. SSH and optional features start disabled.
