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

PC and laptop profiles explicitly import `hosts/common/desktop.nix` for identical selections and `hosts/common/actline-development.nix` for scoped development aliases/CA trust. These files sit outside discovered roots; do not also add them to the catalog. Host differences and security-sensitive VPN settings stay local. Shared declarations retain their original priority; the [inventory](desktop-host-defaults.md) records what moved and what deliberately stayed local.

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

## Deployment ownership inventory (captured before R01 edits)

All targets below are relative to `~/.config/` unless stated otherwise. PC and
laptop enable the workstation bundle; the server enables only Git from these
user modules, so it deploys none of the listed application files.

| Source / owner | PC target | Laptop target | Ownership mode |
| --- | --- | --- | --- |
| `config/fish/config.fish` | `fish/config.fish` | same | Static file link |
| `config/fish/{conf.d,functions}/` | `fish/{conf.d,functions}/` | same | Recursive trees; containing directories remain writable |
| `config/kitty/kitty.conf` | `kitty/kitty.conf` (17.0) | `kitty/kitty.conf` (appended 13.0 override) | Static file link on PC; host-generated text on laptop |
| `config/starship/starship.toml` | `starship.toml` | same | Static file link |
| `config/niri/config.kdl`, common `sub/` files, `scripts/focus-or-launch` | matching `niri/` paths | same | Static file links; script retains executable bit |
| `config/niri/sub/workspaces-{pc,laptop}.kdl` | `niri/sub/workspaces.kdl` from PC source | same target from laptop source | Host-selected static file link; default profile uses `workspaces.kdl` |
| Noctalia theme generator | `niri/noctalia.kdl`, optional `niri/noctalia-dropdown.kdl`, Kitty/theme outputs | same | Mutable/generated state; never owned by the Niri adapter |
| `config/noctalia/config.toml`, common TOML and dropdown template | matching `noctalia/` files | same | Static sources via Noctalia HM options and explicit file links |
| `config/noctalia/{bar,widgets}-{pc,laptop}.toml` | `noctalia/{bar,widgets}.toml` from PC sources | same targets from laptop sources | Host-selected static file links |
| Noctalia runtime settings | `~/.local/state/noctalia/settings.toml` | same | Mutable state; existing stale-settings pruning stays unchanged; v4 copy installer disabled |
| `config/nvim/` | `nvim/` | same | Activation-time rsync copy with writable permissions; preserves generated `lua/matugen.lua` |
| tmux HM options / `config/sesh/sesh.toml` | `tmux/tmux.conf`, `sesh/sesh.toml` | same | Generated text; sesh substitutes the packaged executable path |
| `config/zen/profile.nix` via Zen HM module | selected `zen/vrrqsw0h.evgen2571` profile | selected `zen/it4r6j1f.evgen2571` profile | Managed profile settings alongside application-owned sessions, logins and databases; never link the whole profile |
| `config/hyprland/{hyprland.conf,sub/}` | disabled | disabled | Static file links at `hypr/hyprland.conf`, `hypr/sub/*` when enabled |
| `config/kdeplasma/{kcminputrc,kwinrc,kxkbrc}` | disabled | disabled | Static file links at XDG root when enabled; explicit names avoid owning unrelated desktop state |
| end4 Hyprland installer | disabled | disabled | Existing opt-in activation-time installation; outside the static adapter |

The safe simplifications are automatic discovery of Niri source leaves (excluding
workspace variants before assigning the selected alias) and recursive linking of
Hyprland's static `sub/` tree. Fish is already recursive. Kitty, Noctalia, sesh,
Neovim and Zen retain their purposeful host/generated/writable boundaries. No new
activation cleanup or migration is needed: existing effective leaf targets stay
identical, and no currently unmanaged file is removed.

### Adding a source file or host override

- **Niri:** add an ordinary static file anywhere under `config/niri/`, add its
  KDL `include` where needed, and stage it in Git (flake sources omit untracked
  files). The adapter discovers source leaves automatically. The three workspace
  sources are excluded from discovery and only the selected `workspaceProfile`
  becomes `niri/sub/workspaces.kdl`; the other variants are not deployed. Keep
  generated `noctalia*.kdl` files out of this source tree. The adapter owns leaves,
  not the live directory, so generated siblings remain writable.
- **Hyprland:** add static includes under `config/hyprland/sub/`; Home Manager
  recursively links them. Keep generated files outside that source subtree.
- **Fish:** add loaded snippets/functions to the existing recursive directories.
  **Starship/KDE:** retain the clear explicit file mappings; add an explicit target
  if a new file is actually needed. KDE's files live directly in the XDG root,
  which must never be linked as a whole.
- **Host variants:** use the existing host profile options (`workspaceProfile`,
  Kitty `fontSize`, Noctalia `profile`/`configFile`). For a new exceptional target,
  exclude its ordinary source from discovery before declaring its selected alias;
  never manage the same effective leaf through both a recursive tree and a child
  declaration. Inspect evaluated `home.file` targets, including recursive leaves.
- **Writable/generated applications:** change the owning module deliberately.
  Do not extend static discovery into Neovim, Noctalia's runtime outputs, Zen
  profiles or Skillshare resources. Noctalia's explicit template/common/profile
  links avoid importing its v4 reference files, scripts and runtime state.

`tests/config-paths/` checks automatic nested-file deployment and the existing
workspace/terminal adapter contracts; it is registered as the `config-paths`
flake check. A deployment refactor should also compare evaluated Home Manager
files and activation entries for both desktops (and the server for shared modules)
against the previous revision, preserving content, source/text mode, effective
leaf targets and executable permissions. A source store path changing because the
flake revision changed is not itself a content change.
