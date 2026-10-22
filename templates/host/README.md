# New host template

Copy this directory to `hosts/<your-host>/` and follow [the host guide](../../hosts/README.md).

`configuration.nix` is for your machine, login, networking, and boot setup. `profile.nix` selects the modules you want. Generate your own `hardware-configuration.nix` from NixOS installation media.

The template has **no enabled optional features or secrets**. It also locks password login and won't evaluate until you provide a hostname, public SSH key, and reachable SSH firewall policy. Set up console/password access separately if you need graphical login.
