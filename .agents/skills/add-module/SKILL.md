---
name: add-module
description: Add a new optional NixOS or Home Manager feature, such as an application, development tool, or system service. Not for edits to existing application configs.
---

# Add an optional module

1. Inspect the closest existing module and its host selections. Choose NixOS,
   Home Manager, or paired modules according to the feature's needs.
2. Follow its directory, naming, and `my.*` option conventions. Use
   `lib.mkEnableOption` and guard the feature with `lib.mkIf cfg.enable` so it
   stays independently enableable and disableable. Keep reusable behavior in
   `modules/`, host choices in `hosts/<host>/profile.nix`, and app configs in
   `config/` using the existing adapters where applicable.
3. Follow [module discovery](../../../lib/module-discovery.nix): `*.nixos.nix` or
   `nixos.nix` for system modules; `*.home.nix` or `home.nix` for Home Manager.
   Check [the catalog](../../../lib/module-catalog.nix) for supported directories,
   scopes, and host profiles. Already-discovered modules need no manual import.
4. Add a commented option to [the host template](../../../templates/host/profile.nix).
   Enable it on existing hosts only when requested. Preserve individual feature
   switches; don't replace them with a central package list or automatic enablement.
5. Stage only new task files so Git-backed flakes see them. Evaluate the feature's
   effects both enabled and disabled, then build the enabled result. Use
   `extendModules` for temporary evaluation overrides without changing host
   selections; use existing `just` recipes where applicable.

See [modules](../../../modules/README.md) for option paths and examples.
