# Server-only Hide.me gateway

This is the **current architecture and operational verification guide**, based on the versioned Nix configuration. Git source alone cannot prove the live generation, credentials, connectivity, DNS isolation or whether initial acceptance has been completed. Check running hosts through normal host-networked operator sessions before drawing those conclusions.

For changes to implementation read [agents/networking.md](agents/networking.md). For low-level primitives and private bootstrap procedures see [network-namespaces.md](network-namespaces.md). The [original rollout plan](archive/shared-vpn-gateway-implementation-plan.md) and [full initial rollout runbook](archive/shared-vpn-initial-rollout-runbook.md) are historical snapshots, **not** present-tense execution plans.

## Topology and boundaries

```text
Codex / explicit orca-vpn on nixos-pc or nixos-lp
  → client vpn netns (shared0, isolated DNS and firewall)
  → host Tailscale UDP transport
  → nixos-server vpn netns (shared0)
  → namespace forwarding/NAT → Hide.me hm0
  → restricted provider underlay tap0 → Internet
```

`nixos-server` is the only Hide.me provider. Desktop `vpn` namespaces are WireGuard clients and must not start a local Hide.me provider or slirp underlay. Ordinary host networking, SSH, browsing, updates and Docker do not inherit the selected application's VPN route. Codex uses the registered namespace launcher; normal Orca stays on host networking so host SSH remains available, while `orca-vpn` is opt-in. A running ordinary Orca instance may capture a second invocation through its single-instance behavior, so check the launched process rather than assuming the wrapper changed an existing session.

This mechanism provides network isolation for selected processes, not general containment against a trusted host owner or connected host services. The launcher allows fixed registered applications and refuses arbitrary privileged commands.

## Declarative ownership

| Layer | Files |
| --- | --- |
| Host selection, client addresses and gateway peer declarations | `hosts/{pc,laptop,server}/profile.nix` |
| Public WireGuard peer keys | `hosts/vpn-public-keys.nix` |
| Namespace options, firewall, provider, health | `modules/system-services/network-namespaces/default.nix` and `namespace.nix` |
| Shared WireGuard transport, DNS and desktop provider guards | `modules/system-services/network-namespaces/shared.nix` and `migration/` |
| Restricted application registry and entry helper | `modules/system-services/network-namespaces/launcher.nix`, `packages/namespace-launcher/` |
| Client app wrappers | `modules/user-ai/codex.nix`, `modules/user-ai/orca.nix` |
| Hide.me provider package | `packages/hide-me/default.nix` |
| Host runtime secret declarations | `hosts/{pc,laptop,server}/secrets.nix` and `modules/secrets.nix` |
| Regression checks | `tests/network-namespaces/`, `flake/verification.nix` |

The configuration defines `10.77.0.2/24`, `fd77::2/64` for PC and `10.77.0.3/24`, `fd77::3/64` for laptop. The gateway uses `10.77.0.1/24` and `fd77::1/64`, with client peer prefixes `/32` and `/128`. MTU is configured to 1280. The client endpoint in the current host profiles is `100.96.206.10:51877` over Tailscale. This is a configured address, not a guarantee of present tailnet reachability; recheck it on the hosts when troubleshooting.

Server runtime authentication comes from protected SOPS-managed paths, including the WireGuard private key and the Hide.me bootstrap token. Each desktop also consumes its own protected private key. **Never** print/decrypt credentials or write them into a Nix expression or PR. The provider retains a protected mutable token for refreshes; changes in the SOPS seed are handled by the existing bootstrap digest mechanism. Secret provisioning cannot be inferred from the Git repository; inspect the health/readiness result instead.

## Network, failure and lifecycle contracts

The server namespace firewall permits loopback, tunnel `hm0`, shared-client replies and tightly marked TCP/UDP over restricted `tap0` for the provider. Gateway forwarding is scoped to `shared0 → hm0` and established replies. The provider maintains independent routing/killswitch protections. Desktop namespace output allows only loopback and `shared0`, with no provider/underlay fallback. The namespace-only DNS relay resolves through the provider's private resolver, and app mount/NSS restrictions prevent host resolver fallback.

Clients fail closed if transport, route, DNS, provider or readiness checks fail. The health timer attempts HTTPS egress probes every 30 seconds; new launch readiness requires a recent successful probe (90 seconds) **and** local route, firewall, interface and handshake checks. A recent success is not proof that every API works; do not weaken the probe or allow host-network fallback to fix a particular endpoint.

Client activation installs persistent masks for the old `hide-me-vpn.service` and `netns-vpn-underlay.service`, preventing old local providers from returning even on an older NixOS generation. These masks are intentionally outside normal generation rollback. Shared namespace unit changes may restart the namespace and interrupt existing isolated processes. On the gateway, the night-suspend timer is disabled by the gateway role so regular VPN access is not silently interrupted.

## Read-only status and diagnosis

Use a **normal host terminal**, not a VPN-isolated Codex shell, to inspect the hosts. Exact status is observable only on each live machine:

```sh
readlink -f /run/current-system
systemctl show netns-vpn.service netns-vpn-shared.service \
  -p LoadState -p ActiveState
systemctl status netns-vpn-health.timer --no-pager
sudo /etc/network-namespaces/vpn-check
```

On the server, inspect provider and resolver services too:

```sh
systemctl show hide-me-vpn.service netns-vpn-underlay.service netns-vpn-dns.service \
  -p LoadState -p ActiveState
systemctl status tailscaled.service --no-pager
```

On desktop hosts, the legacy provider/underlay units should be masked and inactive. Inspect their state without changing masks:

```sh
systemctl show hide-me-vpn.service netns-vpn-underlay.service \
  -p LoadState -p ActiveState
```

For an incident, capture (without leaking credentials) systemd journal errors, namespace route tables, WireGuard handshake timestamps, isolated resolver mapping and nftables chains. Correlate all three hosts: a healthy namespace service alone does not establish real egress, and a healthy tunnel handshake alone does not establish working DNS/application requests. Compare host-network reachability separately from isolated-app reachability.

A real leak/failover test, `systemctl restart`, changing DNS in place, blocking UDP or testing old-generation rollback are **state-changing actions** that require an approved maintenance window and independent recovery console. Do not issue them as routine diagnostics.

## Verification versus deployment

Safe development commands on a capable non-live test host/checkout:

```sh
nix flake check --no-build
nix flake check
nix run .#shared-vpn-test
nix build --no-link .#nixosConfigurations.nixos-server.config.system.build.toplevel
nix build --no-link .#nixosConfigurations.nixos-pc.config.system.build.toplevel
nix build --no-link .#nixosConfigurations.nixos-lp.config.system.build.toplevel
```

The full flake and namespace harness exercise isolated fixtures; they do not replace approved **real-provider** egress, DNS-leak, fault-recovery and client-application acceptance on each host. `--no-build` evaluates checks without executing their test programs. Always report exactly which commands ran.

**Deployment is a separate operator decision.** Before an authorized gateway/client change, establish the current generation and backup/recovery path on all involved machines, preserve normal host SSH, schedule affected-app interruptions, and validate both IPv4 and IPv6 failure modes. Desktop provider guards and persistent masks must remain intact. Existing runtime state and generation-specific rollback behavior cannot be inferred solely from the implementation history.

## Historical rollout records

The [archived implementation plan](archive/shared-vpn-gateway-implementation-plan.md) records test intentions, an earlier state of provisioning and a one-time rollout procedure. In particular, statements there about unprovisioned credentials or no live activation are **not statements about the current hosts**. Do not use its first-deployment migration and rollback scripts during routine updates.
