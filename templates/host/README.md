# New host template

Copy this directory to `hosts/<your-host>/` and follow [the host guide](../../hosts/README.md).

`configuration.nix` is for your machine, login, networking, and boot setup. Generate your own `hardware-configuration.nix` from NixOS installation media. It also shows optional desktop/server baseline imports; choose at most one if you want those defaults.

Use `profile = moduleProfiles.all;` in your `mkHost` entry in `flake/hosts.nix`. This makes every optional desktop, server, and Home Manager module available without enabling it. Existing desktop/server catalog profiles remain available for narrower configurations.

[`profile.nix`](profile.nix) lists every optional feature. Uncomment an `enable = true;` line to select it. Blocks include required settings and dependency notes; edit them for your own hardware. For a Niri desktop, enable the Niri system session, Niri user config, Noctalia shell, and Noctalia greeter entries shown in the profile.

The workstation bundle enables common development tools by default. Uncomment individual switches with `false` to disable selected tools from that bundle. Choose either desktop Syncthing or server Syncthing; the server version needs storage enabled and a real storage device. Configure credentials before enabling the VPN, following [the secrets note](../../docs/secrets.md).

The template has **no enabled optional features or secrets**. The imported SSH client module still manages GitHub/server aliases; its settings are shown in the profile. Password login is locked, and the template won't evaluate until you provide a hostname, public SSH key, and reachable SSH firewall policy. Configure a working sudo authentication method before installation, and console/password access if you need graphical login.
