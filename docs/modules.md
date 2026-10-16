# Module conventions

This is the canonical implementation guide for NixOS and Home Manager modules in this repository. For the architectural reasons behind these rules see [../ARCHITECTURE.md](../ARCHITECTURE.md); for an agent's operating rules see [../AGENTS.md](../AGENTS.md).

## How a feature reaches a host

```text
flake/hosts.nix
  → lib/module-catalog.nix (desktop/server roots)
  → lib/module-discovery.nix (module entry points)
  → module declares an option and its guarded implementation
  → hosts/<host>/profile.nix enables/configures the option
```

A discovered module is **available**, not enabled. Modules typically define a `lib.mkEnableOption` and gate their behavior with `lib.mkIf cfg.enable`.

Discovery walks `.nix` files recursively. A directory with a `default.nix` is imported **as that single module**, so implementation files beside it are not individually discovered. The `default.nix` must explicitly import any helpers that are NixOS or Home Manager modules. Do not add imports to host profiles for a module already discovered through the catalog.

The current root selection is:

| Root | Scope | Imported for |
| --- | --- | --- |
| `modules/desktops/` | NixOS | Desktop |
| `modules/hardware/` | NixOS | Desktop |
| `modules/system-apps/` | NixOS | Desktop |
| `modules/system-dev/` | NixOS | Desktop |
| `modules/system-files/` | NixOS | Desktop |
| `modules/system-services/` | NixOS | Desktop and server |
| `modules/server/` | NixOS | Server |
| `modules/user-ai/` | Home Manager | Desktop |
| `modules/user-apps/` | Home Manager | Desktop |
| `modules/user-desktop/` | Home Manager | Desktop |
| `modules/user-dev/` | Home Manager | Desktop and server |
| `modules/user-files/` | Home Manager | Desktop |

`modules/system-core/common.nix`, `modules/system-core/server.nix`, and `modules/system-core/user.nix` are imported explicitly by applicable host configurations. `modules/secrets.nix` is explicitly imported by `flake/hosts.nix`. These are not discovered catalog roots.

## Choose the correct scope

- **NixOS module:** systemd system services, hardware, boot, networking, firewall, system-wide package integration, display manager and session plumbing. Pick the nearest relevant system root.
- **Home Manager module:** user applications, editors, per-user toolchains, XDG files, shell, Git, desktop user configuration and user services. Pick a `user-*` root.
- **Host profile:** toggles, addresses, machine-specific settings, display/workspace selection and intended differences among machines.
- **Source dotfile:** program-native configuration in `config/`, deployed by a user module through Home Manager or a documented activation adapter.

A program may need both a system module and a user module. For Niri, for example, `modules/desktops/niri/default.nix` owns the system session while `modules/user-desktop/niri/config.nix` and `config/niri/` own user settings.

## Implementation patterns

Match the closest sibling first. A typical Home Manager app module:

```nix
{ config, lib, pkgs, ... }:
let
  cfg = config.my.user.apps.example;
in
{
  options.my.user.apps.example.enable =
    lib.mkEnableOption "Example application";

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.example ];
  };
}
```

A typical NixOS system service module:

```nix
{ config, lib, ... }:
let
  cfg = config.my.system.services.example;
in
{
  options.my.system.services.example.enable =
    lib.mkEnableOption "Example service";

  config = lib.mkIf cfg.enable {
    services.example.enable = true;
  };
}
```

Select an app for a specific host in `hosts/<host>/profile.nix`:

```nix
my.primaryUser.home.settings.my.user.apps.example.enable = true;
```

Select a system service using its system option namespace in the same host profile. The primary-user adapter translates the deferred Home Manager settings into `home-manager.users`; do not bypass it with parallel host-local Home Manager configuration.

Prefer `lib.mkDefault` only when providing overridable defaults (for example the workstation bundle). Avoid unnecessary `lib.mkForce`, hidden side effects and dynamic host-name checks inside general modules. Keep `system.stateVersion` and `home.stateVersion` stable during normal updates.

## Managing application files

Modules should use `xdg.configFile`, application-specific Home Manager options, or `lib/config-paths.nix` for source mappings. The path adapters centralize shared sources and machine-specific mappings; Niri's workspace profile is an example.

Do not assume all `config/` trees are static symlinks. Neovim's activation copies the source tree while preserving a generated Matugen theme; Noctalia and browser profiles also have managed/unmanaged boundaries. Inspect the owning module before changing a file-install strategy.

Secrets must be wired as protected runtime paths, typically via sops-nix, never read into Nix strings or embedded in generated world-readable config.

## Before declaring work complete

1. Verify the file is included by the intended catalog profile and that the feature is enabled only on the intended host(s).
2. Check option type/default conventions and interactions with existing bundles or host settings.
3. Validate formatting, evaluate affected configurations, and perform non-activating builds as appropriate.
4. For shared, network, auth, storage or systemd changes, broaden checks and document the safe deployment/rollback procedure.
5. Report checks actually run and any runtime validation not performed. Do not activate a live system without explicit authorization.

Task-specific entry points and relevant existing tests: [task routing](task-routing.md).
