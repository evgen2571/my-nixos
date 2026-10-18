# Obsolete configuration audit — issue #16

Audited 2026-10-17 on `nixos-lp`. This patch changes declarative Niri
package selection and source KDL only; no configuration was activated and no
runtime data, service, network route or generation was removed.

## Inventory

Discovery was checked in `lib/module-discovery.nix` and `lib/module-catalog.nix`:
individual Nix files are imported recursively unless a directory owns `default.nix`.
Desktop system/Home Manager roots apply to PC/laptop, not server; system services
apply to all three. Disabled declarations are still part of the option interface.

| Exact paths | Options / dependencies and references | PC / laptop / server | Recovery or compatibility; decision |
| --- | --- | --- | --- |
| `config/niri/sub/startup.kdl` (satellite command only) | Niri startup include from `config/niri/config.kdl`; system module owns package availability | Niri on / on / absent | **Remove manual spawn**: installed Niri 26.04 already attempts integrated satellite startup (journal evidence below). Avoid competing process ownership; retain all other startup commands. |
| `modules/desktops/hyprland/default.nix`, `modules/user-desktop/hyprland/config.nix`, `modules/user-desktop/hyprland/end4-dots.nix`, `config/hyprland/` | `my.desktop.hyprland`, `my.user.desktop.hyprlandConfig`, `my.user.desktop.end4HyprlandDots`; `hosts/common/desktop.nix`, `lib/config-paths.nix`, `tests/config-paths/default.nix`, `docs/development/modules.md` | explicitly disabled / explicitly disabled / not imported | **Defer**: live option and adapter interfaces; intended fallback retirement has not been established. end4 activation also owns mutable checkout/backup boundaries. |
| `modules/desktops/cinnamon/default.nix` | `my.desktop.cinnamon`; explicit false in common desktop profile | disabled / disabled / not imported | **Defer**: alternate session intent unknown; disabled does not prove retired. |
| `modules/desktops/gnome/default.nix` | `my.desktop.gnome`; individual desktop profiles | disabled / enabled / not imported | **Keep**: active laptop GNOME selection. |
| `modules/desktops/kdeplasma/default.nix`, `modules/user-desktop/kdeplasma/config.nix`, `config/kdeplasma/` | `my.desktop.kdeplasma`, `my.user.desktop.kdeplasmaConfig`; PC explicit false, laptop defaults false; adapter/tests in `lib/config-paths.nix`, `tests/config-paths/default.nix` | disabled / disabled / not imported | **Defer**: evaluated Plasma is false on both desktops despite PC comment describing selectable Plasma. Preserve alternative-session interface pending owner decision; do not infer runtime sessions from Git. |
| `modules/user-desktop/noctalia/config.nix`, `config/noctalia/v4/` | `my.user.desktop.noctalia.legacyConfig.enable`; declared in `modules/user-desktop/noctalia/default.nix`; copies v4 JSON/plugins/templates | legacy false, shell on / legacy false, shell on / not imported | **Keep**: explicit rollback/reference contract in module; current TOML deployment remains unchanged. |
| `modules/system-services/vpnbook-wireguard-failover.nix` | `my.system.services.vpnbookWireguardFailover`; discovered on all hosts; archived references in `docs/archive/server-initial-setup-notes.md` | default false / default false / default false | **Defer**: no current enablement found, but private runtime configurations and recovery intent are not established. Do not inspect credentials or unmask/start legacy units. |
| `modules/system-services/network-namespaces/migration/` | `shared.nix` reads `desktop-provider-guard.sh`; dedicated `tests/network-namespaces/` and `docs/guides/shared-vpn-gateway.md` retain guards/rollback procedures | client / client / gateway | **Keep**: guards and persistent provider masks participate in fail-closed operation and older-generation rollback. First deployment is not end of lifecycle. |

No module or asset tree was proven safe to retire. The only removal is the
obsolete manual satellite startup command. No host option declarations, adapters,
historical documents, SSH/Tailscale, VPN or server configuration were changed.

## Laptop Steam investigation

The running session is Niri 26.04, launched with `--session`, on Wayland.
Before the change:

```text
DISPLAY= WAYLAND_DISPLAY=wayland-1 XDG_SESSION_TYPE=wayland
niri: error spawning xwayland-satellite at "xwayland-satellite", disabling integration: No such file or directory (os error 2)
systemctl: Environment variable $DISPLAY not set, ignoring.
```

`command -v xwayland-satellite` failed; no satellite/Xwayland process was present.
Only the three display/session variables were inspected. Fish, Niri-spawned
shell and the user systemd environment all lacked DISPLAY. Direct Steam and
Niri-spawned Steam produced no captured stderr and no Steam window/process.
Thus the missing satellite is verified; the exact user-visible Steam error
and absence of an additional Steam runtime problem are **not** verified.
The desktop entry uses `Exec=steam %U`; clicking it through Noctalia and launching
from an actual Kitty window remain unverified.

The fix installs satellite whenever Niri is enabled, leaving its built-in
integration to allocate DISPLAY and own startup. No hard-coded display number,
Steam wrapper or global environment override is introduced. PC Steam and
gamescope settings remain unchanged; PC Niri receives the same missing dependency.

## Runtime follow-up (still open)

After an operator-authorized deployment and a fresh Niri login, verify satellite
startup on demand, DISPLAY in new Fish/Kitty processes, Niri/Noctalia desktop-entry
launch and the user systemd environment. Obtain a visible interactive Steam
window and check another X11 app plus a Wayland app. Record any secondary Steam
error. Do not mark issue #16 runtime acceptance complete from evaluation alone.

## Validation evidence

- `nix flake check --no-build`: passed, including all three host evaluations.
- Full `nix flake check`: passed, including the shared VPN systemd VM test.
- Focused `niri-host-profiles` check: passed; removing satellite caused its
  assertion to fail, then restoring the package passed again.
- Non-activating laptop toplevel build: passed.
- Before/after evaluated Steam/Niri/GNOME/Plasma/VPNBook enablement: identical
  across PC, laptop and server.
- `nixfmt --check` for changed Nix files, `git diff --check`, referenced-path
  inspection and `niri validate -c config/niri/sub/startup.kdl`: passed.
- Full source KDL validation cannot resolve the intentionally generated
  `config/niri/noctalia.kdl`; no claim of full session validation is made.
- Interactive Steam launch remains unverified after the fix; no deployment,
  compositor restart, logout or service restart was performed.

The user accepted a reduced verification scope: the optional full PC build was
stopped during dependency compilation. PC evaluation and host checks passed;
the complete PC build and post-deployment Steam checks are left to the user.
