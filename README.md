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

home/operator/home.nix   base Home Manager user config

lib/module-discovery.nix  recursive module discovery helper
lib/module-catalog.nix    profile import sets built from discovered module roots
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
- `lib/module-catalog.nix` — see which discovered module roots each profile imports.

For a new app/tool:

1. Add a small module under the right `modules/user-*` or `modules/system-*` folder.
2. Enable it in `hosts/<host>/profile.nix`.

`lib/module-discovery.nix` only scans the module hierarchy for importable modules. `lib/module-catalog.nix` groups those discovered modules into profile import sets. New modules should not need separate path/import bookkeeping.

Rule of thumb:

- `configuration.nix` = machine basics and hardware-ish decisions.
- `profile.nix` = toggles for this machine.
- `modules/` = reusable logic.
- `config/` = raw dotfiles copied/linked by modules.

## Adding a new module

1. Pick the scope.
   - Use a NixOS/system module when it configures system services, hardware, desktop sessions, users, drivers, or system packages.
   - Use a Home Manager/user module when it configures user apps, dotfiles, shells, editor config, or `home.packages`.

2. Put the module in the matching folder.
   - System examples: `modules/system-services/`, `modules/system-apps/`, `modules/hardware/`, `modules/desktops/`.
   - User examples: `modules/user-apps/`, `modules/user-dev/`, `modules/user-desktop/`, `modules/user-files/`.
   - Prefer copying the shape of the closest sibling module.

3. Give it a small enable option.

   System module pattern:

   ```nix
   { config, lib, pkgs, ... }:
   let
     cfg = config.my.system.services.example;
   in
   {
     options.my.system.services.example.enable = lib.mkEnableOption "Example service";

     config = lib.mkIf cfg.enable {
       environment.systemPackages = with pkgs; [ example ];
     };
   }
   ```

   Home Manager module pattern:

   ```nix
   { config, lib, pkgs, ... }:
   let
     cfg = config.my.user.apps.example;
   in
   {
     options.my.user.apps.example.enable = lib.mkEnableOption "Example app";

     config = lib.mkIf cfg.enable {
       home.packages = with pkgs; [ example ];
     };
   }
   ```

4. Let the catalog import it through the matching discovered profile root.
   - `modules/desktops`, `modules/hardware`, `modules/system-apps`, `modules/system-dev`, and `modules/system-files` are discovered for desktop NixOS hosts.
   - `modules/system-services` is discovered for both desktop and server NixOS hosts.
   - `modules/user-ai`, `modules/user-apps`, `modules/user-desktop`, and `modules/user-files` are discovered for desktop Home Manager profiles.
   - `modules/user-dev` is discovered for both desktop and server Home Manager profiles.
   - A directory with `default.nix` is treated as one module; otherwise `.nix` files below the root are discovered recursively.

5. Enable it per host in `hosts/<host>/profile.nix`.
   - System modules usually toggle `my.system.*` or another system option namespace.
   - User modules should usually go through the primary-user adapter:

   ```nix
   my.primaryUser.home.settings.my.user.apps.example.enable = true;
   ```

6. Verify before rebuilding.

   ```bash
   nix fmt
   git diff --check
   nixos-rebuild build --flake .#nixos-pc
   ```

   Use the target host name for host-specific changes, for example `.#nixos-lp` or `.#nixos-server`.

Do not add per-module imports manually. Discovery makes modules available by scanning the configured roots, and `lib/module-catalog.nix` decides which profile imports each root. Add or change catalog roots only when a whole folder should become available to a different profile.

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

For the NixOS server, see [Server setup and operations](docs/server.md).

See [the KDE Plasma workflow guide](docs/kde-plasma.md) for the Niri-like focus,
keyboard timing, tiling, and Unity/Neovim setup.

## Small notes for future me

- Keep modules boring and easy to delete.
- Prefer one module per tool/service.
- Put modules under the discovered `modules/*` roots; keep profile imports catalog-derived.
- If a module has an `enable` option, the host should toggle it from `profile.nix`.
- Do not hide host-specific choices inside reusable modules.
- When adding a new module root or changing which profiles should discover a root, update `lib/module-catalog.nix` and keep the root grouping easy to read.
- For Neovim plugins, look in `config/nvim/lua/custom/plugins/` first.
- For Telescope/keymap behavior, check `config/nvim/lua/kickstart/plugins/telescope.lua`.
