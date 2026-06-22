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

lib/module-paths.nix      named paths for every module
lib/profile-imports.nix   which modules belong to desktop/server profiles
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
- `lib/module-paths.nix` — find the file behind a module name.
- `lib/profile-imports.nix` — check whether a module is imported at all.

For a new app/tool:

1. Add a small module under the right `modules/user-*` or `modules/system-*` folder.
2. Register it in `lib/module-paths.nix`.
3. Add it to `lib/profile-imports.nix` if it should be available for that profile.
4. Enable it in `hosts/<host>/profile.nix`.

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
- Put shared imports in `profile-imports.nix`, not directly in every host.
- If a module has an `enable` option, the host should toggle it from `profile.nix`.
- Do not hide host-specific choices inside reusable modules.
- When adding a path, keep `module-paths.nix` alphabet-ish and grouped.
- For Neovim plugins, look in `config/nvim/lua/custom/plugins/` first.
- For Telescope/keymap behavior, check `config/nvim/lua/kickstart/plugins/telescope.lua`.
