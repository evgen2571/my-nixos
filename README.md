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

4. Add one catalog entry in `lib/module-catalog.nix`.
   - `attrPath` keeps the old `modulePaths.*` shape for compatibility.
   - `scope` is `system` for NixOS modules and `home` for Home Manager modules.
   - `category` is a simple grouping such as `app`, `service`, `desktop`, `hardware`, `development`, `files`, `ai`, or `core`.
   - `profiles` controls which shared profile imports it. Use `[ "desktop" ]`, `[ "server" ]`, `[ "desktop" "server" ]`, or `[ ]` for host-base modules imported directly by `hosts/*/configuration.nix`.
   - The final string should say what the module means, not just repeat the filename.

   Example entries:

   ```nix
   (systemModule [ "systemServices" "example" ] "/modules/system-services/example.nix" "service" [ "desktop" ] "Example system service.")
   (homeModule [ "user" "apps" "example" ] "/modules/user-apps/example.nix" "app" [ "desktop" ] "Example desktop app.")
   ```

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

Do not add new imports directly to `lib/profile-imports.nix`; it is derived from the catalog. Keep `lib/module-paths.nix` as a compatibility view unless the whole repo is intentionally migrated away from `modulePaths`.

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
