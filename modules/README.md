# Modules

Hosts choose which features to enable in `hosts/<host>/profile.nix`. Modules define
those features; application configs live in [`config/`](../config/README.md).

Modules are discovered automatically: `*.nixos.nix` and `nixos.nix` are system
modules; `*.home.nix` and `home.nix` are Home Manager modules for user settings.
Adding one under the existing feature directories doesn't need a manual import
and doesn't enable it.

The [host template profile](../templates/host/profile.nix) lists the optional
switches. Apps can be enabled or disabled individually, including when a bundle
such as `workstation` enables them by default.

For example, to enable my Git setup:

```nix
my.primaryUser.home.settings.my.user.dev.git.enable = true;
```

System options usually live under `my.system.*` or `my.desktop.*`; user options
live under `my.primaryUser.home.settings.my.user.*`.

New hosts can use `moduleProfiles.all` to make every optional module available.
My desktop and server profiles use smaller selections. If you're adding a feature,
follow a nearby module and update the host template's switches.
