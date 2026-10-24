# Modules

Most things in this repo are optional NixOS or Home Manager modules. Each host picks what it needs in `hosts/<host>/profile.nix`.

The naming is pretty literal: `*.nixos.nix` (or `nixos.nix`) is a system module; `*.home.nix` (or `home.nix`) is for Home Manager. The module catalog discovers those files in the supported directories. Just adding a file doesn't enable it.

The [host template profile](../templates/host/profile.nix) lists every optional feature, with commented switches to enable it. Keep that list current when adding or removing features. New hosts can use `moduleProfiles.all` to make both desktop and server modules available; the `desktop` and `server` catalog profiles keep their existing narrower selections.

For example, to install my Git setup for the primary user:

```nix
my.primaryUser.home.settings.my.user.dev.git.enable = true;
```

System features generally live under `my.system.*` or `my.desktop.*`. User features are under `my.primaryUser.home.settings.my.user.*`. The nearest existing module is usually the best example if you're adding one.

A quick map:

- `hosts/` chooses what each machine uses
- `modules/` defines what those choices do
- `config/` holds Niri, Neovim, and other app-native files
- `lib/module-catalog.nix` and `lib/module-discovery.nix` handle module availability; ordinary additions don't need manual imports

Core account wiring, secrets, and deployment guards are assembled separately. Don't move them into optional discovery or bypass the production private-input checks just to make an evaluation pass.

For daily use, you probably don't need to touch the catalog at all.
