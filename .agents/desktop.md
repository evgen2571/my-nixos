# Agent guide: graphical desktop

Use for Niri, Noctalia, desktop applications, window rules, workspace placement, greeter and session integration. Keep system-level session plumbing separate from Home Manager user configuration.

## Where changes belong

| Task | Owner |
| --- | --- |
| Niri session, portals, polkit and system services | `modules/desktops/niri/default.nix` |
| Niri Home Manager deployment/workspace selection | `modules/user-desktop/niri/config.nix`, `lib/config-paths.nix` |
| Niri entry point and includes | `config/niri/config.kdl` |
| Keybindings and navigation | `config/niri/sub/binds.kdl` |
| Layout/input/startup | `config/niri/sub/layout.kdl`, `input.kdl`, `startup.kdl` |
| Window behavior and app matching | `config/niri/sub/rules/common.kdl`, `rules/apps.kdl`, `rules/apps/*.kdl`, `rules/obsidian.kdl` |
| Host display/workspace topology | `config/niri/sub/workspaces-pc.kdl`, `workspaces-laptop.kdl`, profiles |
| Noctalia configuration / generated colors | `modules/user-desktop/noctalia/`, `config/noctalia/` |
| Noctalia greeter, PAM login | `modules/desktops/noctalia-greeter.nix`, `hosts/laptop/configuration.nix`, [greeter runbook](../docs/guides/noctalia-greeter.md) |
| Zen browser spaces/pins | `config/zen/`, `modules/user-apps/zen-browser.nix`, [Zen runbook](../docs/guides/zen-browser.md) |

PC/laptop common feature selections live in `hosts/common/desktop.nix`, explicitly imported by both local profiles. Keep machine choices in those profiles; consult the [inventory](../docs/reference/desktop-host-defaults.md) before changing a shared selection. VPN settings and wrappers remain host-local.

## Niri: two layers, not two conflicting configs

`modules/desktops/niri/default.nix` installs/configures the system session, graphics portals and associated services. `modules/user-desktop/niri/config.nix` selects the **per-user** KDL source mappings. `lib/config-paths.nix` maps the chosen host-specific workspace source to the deployed `~/.config/niri/sub/workspaces.kdl`. Do not edit only `config/niri/sub/workspaces.kdl` expecting the desktop hosts to use it: both profiles explicitly select `pc` or `laptop`.

`config/niri/config.kdl` includes common rules and source subfiles. `rules/common.kdl` includes `obsidian.kdl`, `apps.kdl` (simple apps), then `apps/{telegram,steam,prism,vesktop,zen,obs}.kdl` (one owner per complex app). Global defaults and cross-app PiP behavior remain in `common.kdl`. Obsidian and Anki policies are unchanged.

The Niri adapter recursively discovers **individual source files**, including nested app rules, for both workspace profiles. Add an include in `common.kdl` and the corresponding source file; no explicit Nix mapping entry is needed. Generated `noctalia.kdl` and optional `noctalia-dropdown.kdl` stay mutable siblings outside source ownership.

Before adding a match, collect `niri msg --json windows` and `niri msg --json workspaces` for the main window and each separate auxiliary window. Match app-id and reliable title together; multiple `match` lines mean OR. Exclude auxiliaries from the main maximize/workspace rule: later rules cannot unset its workspace target. `is-floating` is evaluated after opening and cannot select initial placement. Use proportional floating sizes and default centering; omit workspace routing for auxiliaries. Scope any `open-fullscreen false` to a verified viewer, preserving deliberate game/video/projector fullscreen. See [Niri's matching semantics](https://niri-wm.github.io/niri/Configuration%3A-Window-Rules.html).

Validate a temporary complete deployment tree with each host's workspace source, the installed/configured Niri version, and actual generated Noctalia includes. Do not write test files into the live config. Test dialogs after moving the main window, focus return, resizing and multiple outputs on both hosts. See [R05 observations and remaining checks](../docs/archive/niri-window-rules.md) before extending these rules.

Workspace names (such as `code`, `browser`, `anki`, `gaming`) are logical targets; physical output bindings differ by machine. Check `workspaces-pc.kdl` and `workspaces-laptop.kdl` and the relevant app rule before changing placement or shortcuts.

## Noctalia and login ownership

Noctalia deploys TOML configuration and templates while retaining generated/runtime settings. Niri additionally loads Noctalia-generated KDL includes. Do not commit generated runtime themes or force-write active application databases. For the greeter, a visual change may interact with session authorization; login and fingerprint/keyring behavior is a separate **security-sensitive** concern requiring explicit approval before activation.

## Validation and stop conditions

- Inspect affected profiles, KDL include chain and module options. Validate KDL using an installed Niri command that matches the configured version where available; do not invent or assert tool support.
- Check only affected hosts with non-activating evaluation/builds as warranted.
- Verify actual placement, hover/focus and multiscreen behavior manually on each impacted host; static builds cannot prove UI correctness.
- Do not restart Niri, change PAM, log out a user, replace live profile contents, or run a system switch without explicit authorization.

**Read networking guidance only when the task actually changes VPN/SSH/portal network access.**
