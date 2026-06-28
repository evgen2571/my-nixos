# my-nixos

Personal NixOS + Home Manager config.

This repo is mostly split into small modules. Hosts choose what they need, profiles collect shared imports, and modules keep the actual options/packages/services.

## Quick map

```text
flake.nix                 entry point
flake/hosts.nix           declares nixos-pc, nixos-lp, nixos-server
flake/devshells.nix       tools for working on this repo
flake/formatting.nix      nix fmt setup

hosts/<name>/             host-specific config
hosts/<name>/profile.nix  what that machine enables

home/evgen2571/home.nix   base Home Manager user config

lib/module-catalog.nix    source of truth for module paths, scope, category, and profile availability
lib/module-paths.nix      compatibility view of catalog paths
lib/profile-imports.nix   profile imports derived from the module catalog
lib/config-paths.nix      paths for copied config files

modules/system-*          NixOS modules
modules/user-*            Home Manager modules
modules/desktops          window managers / login / desktop plumbing
modules/hardware          GPU, bluetooth, tablets, capture, etc.

config/nvim               Neovim config
config/fish               shell config
config/niri               Niri config
config/hypr               Hyprland config
```

## How I usually navigate

Start here:

- `flake/hosts.nix` — see all machines and profiles.
- `hosts/pc/profile.nix` — see what the main PC enables.
- `lib/module-catalog.nix` — find the module catalog entry: path, scope, category, and profiles.
- `lib/profile-imports.nix` — profile import views generated from the catalog.

For a new app/tool:

1. Add a small module under the right `modules/user-*` or `modules/system-*` folder.
2. Add one entry to `lib/module-catalog.nix` with its path, scope, category, profiles, and short meaning.
3. Enable it in `hosts/<host>/profile.nix`.

`lib/module-paths.nix` and `lib/profile-imports.nix` are generated views over the catalog, so new modules should not need separate path/import bookkeeping.

Rule of thumb:

- `configuration.nix` = machine basics and hardware-ish decisions.
- `profile.nix` = toggles for this machine.
- `modules/` = reusable logic.
- `config/` = raw dotfiles copied/linked by modules.

## Common commands

```bash
nix develop
nix fmt
nixos-rebuild build --flake .#nixos-pc
sudo nixos-rebuild switch --flake .#nixos-pc
```

Other hosts:

```bash
nixos-rebuild build --flake .#nixos-lp
nixos-rebuild build --flake .#nixos-server
```

## Small notes for future me

- Keep modules boring and easy to delete.
- Prefer one module per tool/service.
- Put module path/scope/category/profile metadata in `module-catalog.nix`; keep profile imports as catalog-derived views.
- If a module has an `enable` option, the host should toggle it from `profile.nix`.
- Do not hide host-specific choices inside reusable modules.
- When adding a catalog entry, keep entries grouped by scope/category and set `profiles` only for profiles that should import it.
- For Neovim plugins, look in `config/nvim/lua/custom/plugins/` first.
- For Telescope/keymap behavior, check `config/nvim/lua/kickstart/plugins/telescope.lua`.
