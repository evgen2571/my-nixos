# Agent guide: networking and VPN

Use for network namespaces, Hide.me gateway/client setup, Tailscale transport, DNS isolation, launcher authorization and VPN recovery. These are **security-sensitive** changes. Use [../shared-vpn-gateway.md](../shared-vpn-gateway.md) as the current design/runbook and [../network-namespaces.md](../network-namespaces.md) for implementation details. Do not start with the archived migration plan.

## Entry points

| Concern | First files |
| --- | --- |
| Host role / client peer addressing | `hosts/pc/profile.nix`, `hosts/laptop/profile.nix`, `hosts/server/profile.nix` |
| Namespace options and assertions | `modules/system-services/network-namespaces/default.nix` |
| Namespace firewall, provider, systemd health | `modules/system-services/network-namespaces/namespace.nix` |
| Shared transport / DNS / desktop provider guard | `modules/system-services/network-namespaces/shared.nix`, `migration/` |
| Restricted app launcher and registry | `modules/system-services/network-namespaces/launcher.nix`, `packages/namespace-launcher/` |
| Client applications | `modules/user-ai/codex.nix`, `modules/user-ai/orca.nix` |
| Server Hide.me packaging | `packages/hide-me/default.nix` |
| Tailscale service and exposure | `modules/system-services/tailscale.nix`, server SSH module |
| Public peer declarations | `hosts/vpn-public-keys.nix` (public material only) |
| Tests | `tests/network-namespaces/`, `flake/verification.nix` |

## Invariants before editing

- The server is the only Hide.me provider and the desktop hosts are isolated WireGuard clients carried over Tailscale. Never add a desktop provider, route fallback, host-wide VPN default route or implicit privileged shell.
- Namespace firewall, DNS and host/namespace route separation must remain fail-closed for **both IPv4 and IPv6**. Include existing-connection behavior, reboot and rollback in the threat model.
- The launcher permits fixed registered commands executed as the authorized normal user; it is **not** a general-purpose sudo escape hatch. Normal Orca uses host networking; the explicit `orca-vpn` wrapper isolates selected sessions.
- Private WireGuard keys and Hide.me bootstrap/auth values are runtime SOPS secrets. Never print, inspect, decrypt or interpolate them into the Nix store. Public keys are in `hosts/vpn-public-keys.nix`.
- Systemd restart/stop relationships, persistent desktop provider masks and the private resolver mounts are design constraints, not incidental implementation complexity.
- The server suspend timer is disabled when its namespace role is `gateway`. Do not accidentally reactivate suspension as a side effect of networking changes.

## Change protocol

1. Identify **which role(s)** are impacted: PC client, laptop client, server gateway, launcher, or generic namespace.
2. Inspect direct modules and assertions plus tests covering those roles. Distinguish host route changes from namespace-only changes.
3. Make a narrow edit. When changing firewall, policy routing, systemd dependencies or guards, specify what must remain blocked on failure.
4. Run relevant network namespace checks through `nix flake check` / `nix run .#shared-vpn-test` when available, and non-activating builds for every affected host.
5. Report tests and risk. **Do not** deploy, restart services, toggle masks, generate keys, rotate secrets, or run migration/rollback scripts without separately authorized live operations with an independent recovery console.

A successful Nix evaluation or VM fixture does not establish working real-world Hide.me egress or prove there are no DNS leaks. Live checks belong to an approved operator session.

See [server operations](../server.md) for host SSH, storage, services and suspend/wake interactions.
