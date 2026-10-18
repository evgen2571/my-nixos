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

Clients fail closed if transport, route, DNS, provider or readiness checks fail. The recovery timer requests isolated HTTPS egress checks every 30 seconds after the previous run finishes; new launch readiness requires a recent successful probe (90 seconds) **and** local route, firewall, interface and handshake checks. A recent success is not proof that every API works; do not weaken the probe or allow host-network fallback to fix a particular endpoint.

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

## Resilience and day-to-day diagnosis

`vpn-status` is installed on PC, laptop and server. Run it from a normal host
terminal as an ordinary user; `vpn-status --verbose` adds the sanitized local
snapshot, unit states, per-family probe exit codes and retained failure record.
It never starts services, reads tokens, performs login, or asks another host for
logs. A client cannot identify the gateway's provider/account failure: run the
same command on the gateway through your existing authenticated host session.
Remote evidence is unavailable until you do so; a reachable Tailscale peer is
not proof of a WireGuard handshake or working Hide.me egress.

Status separates `Applications: READY`, `BLOCKED`, `DEGRADED` or `UNKNOWN`
from `Routing policy: fail-closed`. READY requires a fresh successful snapshot,
the unexpired IPv4 marker, the namespace and currently active required VPN units.
It describes recent verified readiness, not a privileged real-time policy audit:
entry still rechecks routes/filter/handshake/resolver. A failed entry always says
BLOCKED, even if the previous scheduled snapshot was healthy. Stale/unavailable
evidence says UNKNOWN; partial probe success says DEGRADED while IPv4 readiness
remains fresh. Scheduler activity is reported separately: stopping the recovery
timer does not invalidate a still-fresh successful readiness check.

The restricted launcher's readiness failure prints this same diagnosis before
refusing entry. It retains fresh local interface, IPv4/IPv6 route, firewall,
handshake and resolver checks, plus the original 90-second **IPv4** HTTPS marker
expiry. IPv6 probes report degradation separately. A brief failed check does not
remove a still-fresh success; it never extends that success's lifetime.

`netns-vpn-recovery.timer` schedules a host-side oneshot 30 seconds after the
previous run finishes (first run 15 seconds after boot). It requests
`netns-vpn-health.service`, which probes both address families of both configured
HTTPS destinations **inside the namespace and private resolver mounts**. The
standalone role retains its original health timer. The root-owned snapshot in
`/var/lib/network-namespaces-vpn/status.json` is readable by normal users; status
older than 120 seconds is visibly stale. It retains the last failure and last
success independently, plus attempts, backoff, component and verified recovery
time. Status transitions emit JSON journal lines with fixed `VPN_REASON`,
`VPN_PHASE` and `VPN_ATTEMPTS` fields; no provider text is copied into them.

Recovery policy:

- Wait through missing host Internet, Tailscale authentication/offline state and
  unreachable gateway prerequisites. Never restart Tailscale or infer a remote
  account problem. WireGuard normally handles peer reboot, relay changes and
  transient packet loss without interface recreation.
- Apply 120 seconds of boot, recent-service-start and detected resume grace,
  then require three consecutive failed observations. A single successful
  observation resets the failure debounce, but ten healthy minutes are needed
  to replenish the repair budget, preventing flapping from resetting it.
- Repair a missing/failed local `shared0` transport; on the gateway, repair a
  missing/failed `tap0` (including its main-table route), provider interface, provider routes or stale provider
  handshake. Do not recreate a client interface solely for a stale handshake:
  keys/endpoint/UDP policy need inspection if it persists.
- An active provider with sustained independent DNS/connect/timeout failures on
  all probes can receive a provider-only restart after prerequisites pass.
  One failed destination/family, HTTP response errors and TLS errors never
  trigger that repair. A DNS relay restart is permitted only after upstream
  isolated egress succeeds and a direct relay query fails.
- Allow at most three component repairs per unhealthy episode, with minimum
  120/300/900-second backoff. Successful `systemctl restart` means `VERIFYING`,
  never recovery success; a later isolated check must pass. Exhaustion stays in
  `RECOVERY_COOLDOWN` until sustained health or an explicit operator reset.
  The provider wants/orders after the underlay and gates startup on its route;
  it stays alive through underlay process failures instead of being stranded by
  dependency-stop propagation. An explicit guarded underlay repair starts both
  components in one ordered transaction. Fixed root-only start/stop hooks record
  each managed unit's lifecycle under `stops/` in the state directory. Direct
  successful stops with healthy dependencies are recorded as manual; stops while
  namespace/transport dependency jobs are pending are recorded as propagated.
  A later start clears manual intent. Records apply only to the current boot.
  Never-started, condition-skipped and dependency-stopped services may recover;
  historical timestamps alone never establish operator intent. A pre-upgrade
  inactive service without lifecycle evidence yields `STOP_INTENT_UNKNOWN` and
  requires a verified explicit start. Pending jobs are allowed to finish.
  A missing namespace yields `NAMESPACE_UNAVAILABLE`, not a firewall diagnosis;
  failed/inactive namespace startup can be retried with **start**, never teardown.
  Once the namespace is ready, damaged nft policy still requires operator action.
  Missing secrets yield `SECRETS_UNAVAILABLE` until provisioning returns; empty or
  unreadable secrets remain configuration errors.
  Each auto-restarting component also has a three-start/300-second systemd
  limit; the guarded monitor can rearm failed components after prerequisites
  return. Late SOPS provisioning is ordered before transport/provider startup.
- HTTP 401/403 evidence from the current provider invocation yields
  `AUTH_REJECTED`: **authorization rejected; exact cause unknown**. It does not
  establish account or token expiry. HTTP 429 yields `PROVIDER_RATE_LIMITED`.
  Both persist a private recovery hold and stop the provider's own reconnect
  loop. No unattended login/refresh command is attempted. Without reliable
  Retry-After evidence, a 429 hold deliberately requires operator review rather
  than guessing the provider's retry interval. HTTP 5xx receives bounded
  backoff; generic timeouts never become an authentication diagnosis.
- Missing units, bad peer declarations, invalid secrets and broken firewall
  or forwarding checks require action. There is no auto-rebuild, unmask, secret
  replacement, namespace teardown or firewall repair. Ordinary host networking
  and SSH are not modified.

The main reason codes are:

| Code | Interpretation / next step |
| --- | --- |
| `DEPLOYMENT_MISMATCH` | Required unit absent; compare the installed generation and approved deployment. |
| `DISABLED` | Mask, explicit stop or maintenance; recovery does not fight it. |
| `CONFIGURATION_ERROR` | Check empty/unreadable secret paths, SOPS and declared public peers privately. |
| `SECRETS_UNAVAILABLE` | Runtime secret not yet provisioned; wait and inspect SOPS privately. |
| `NAMESPACE_UNAVAILABLE` | Namespace startup/dependency is not ready; no firewall conclusion yet. |
| `STOP_INTENT_UNKNOWN` | Old inactive service lacks lifecycle evidence; verify intent and start explicitly. |
| `HOST_OFFLINE` | Neither family has a usable host route/interface and all host HTTPS checks failed. |
| `HOST_CONNECTIVITY_UNVERIFIED` | HTTPS failed with usable or unknown routes; DNS, TLS, filtering, captive portal or endpoint failure remain possible. |
| `TAILSCALE_OFFLINE` | Check host Tailscale state/authentication without restarting it blindly. |
| `GATEWAY_UNREACHABLE` | Peer did not respond; power/uplink/Tailscale are possible causes, provider state unknown. |
| `TRANSPORT_MISSING`, `WG_HANDSHAKE_STALE` | Inspect shared interface, endpoint, peer keys and UDP filtering. |
| `UNDERLAY_UNAVAILABLE`, `PROVIDER_UNHEALTHY` | Local gateway component failed or stuck; bounded targeted recovery. |
| `AUTH_REJECTED` | Current provider logged HTTP 401/403; follow private credential verification below. |
| `PROVIDER_RATE_LIMITED`, `PROVIDER_API_UNAVAILABLE` | Observed HTTP 429 or 5xx, distinct from rejected credentials. |
| `DNS_UNAVAILABLE` | Private DNS failed; never substitute host/public DNS. |
| `CLOCK_ERROR` | Future handshake/backwards clock evidence; verify time before repair. |
| `FIREWALL_ERROR`, `ROUTE_ERROR` | Inspect namespace filtering/forwarding/NAT or family routes. |
| `EGRESS_UNAVAILABLE`, `EGRESS_DEGRADED` | All or some HTTPS checks failed; inspect individual results before assigning cause. |

Host route/interface observations and per-family HTTPS outcomes are recorded
separately. `Host probes: IPv4 passed; IPv6 unverified` describes the probes,
not a conclusion that the whole IPv6 uplink is down. A successful family permits
continued diagnosis; all failed host probes make recovery wait without tearing
down VPN components, even when the underlying Internet cause remains unknown.

Isolated probe results are ordered IPv4 URLs then IPv6 URLs in configured order. Common
curl exit codes: `0` success, `6` DNS, `7` connection, `22` HTTP response error,
`28` timeout, `35`/`60` TLS/verification. TLS failure alone cannot distinguish
clock skew from certificate or endpoint problems. Snapshots are observations,
not proof of every nft rule, peer's state or application API's availability.

### Maintenance, reset and credential rejection

A recorded direct stop of a required unit is respected. For concurrent service
operations, use the explicit maintenance flag so intent is unambiguous. For a maintenance window
that also covers a partially failed/auto-restarting unit, set a persistent flag
**before** stopping it:

```sh
sudo touch /var/lib/network-namespaces-vpn/maintenance
# Perform only separately approved maintenance.
sudo rm /var/lib/network-namespaces-vpn/maintenance
```

After examining the cause, an operator can reset the budget/authorization hold:

```sh
sudo /etc/network-namespaces/vpn-recovery-reset
```

The reset itself does not start units or bypass readiness/isolation. Subsequent
checks can recover a provider previously stopped by the doctor; a recorded
operator stop still requires an explicit start under approved maintenance.
An unchanged bootstrap seed preserves the provider's refreshed mutable token.
Changed seed/token contents release an authorization hold; private fingerprints
keep an identical SOPS seed re-materialized at boot from clearing it. Fingerprints
are stored only in the root-readable hold, never in public status or journals;
the existing prepare script alone decides when a changed bootstrap replaces the
mutable token. Reauthorization keeps the rejected invocation excluded while
prerequisites return, then permits a bounded fresh provider start. An inactive
unit's retained InvocationID is never fresh authorization evidence. The provider
invocation is refreshed after probes and rechecked before acting: the old 401
cannot re-latch the hold after renewal, while a new attempt's 401 can. Holds from
earlier versions are upgraded using their saved invocation evidence. Health,
not start completion, clears the released hold. The hold survives monitor
restarts and reboot. A manual budget reset never copies or removes token files.

For confirmed invalid credentials, use the [private bootstrap procedure](network-namespaces.md#private-server-authentication).
First verify account status privately with Hide.me; payment/account renewal and
token renewal are separate operations. A generic 401 does not tell you which is
needed. Do not replace a valid refreshed token with an old SOPS seed. Create a
fresh bootstrap only when credential renewal is confirmed necessary, update only
the encrypted SOPS seed, and deploy/restart through an approved operator session.
Never paste token values or raw provider logs into an issue/PR. The doctor reads
only bounded current-invocation journal evidence and publishes fixed codes.

### October 17 evidence and limitations

The earlier missing desktop `netns-vpn-shared.service` was a deployment mismatch;
a watchdog cannot install that unit. The later incident had a running provider,
HTTP 401, a loopback-only degraded resolver and persistent server/client egress
failure despite working Tailscale ping. The simulated regression reproduces that
combination and asserts a durable authorization hold, no restart/login storm,
no expiry claim and no raw-log disclosure. The original 17:35–17:50 server
journal and suspend initiator were unavailable from the development workspace
(`nixos-server` did not resolve). No precursor or account-expiry cause is claimed.
The gateway night-suspend timer remains disabled; investigate logind/systemd
sleep journals privately to attribute unexpected suspend to a manual/external
request. Resume detection does not promise to wake a powered-down gateway.

### Separately approved live validation matrix

These tests **change live state** and were not performed by development checks.
Use independent host SSH/console access, a rollback generation and an agreed
maintenance window. Capture sanitized `vpn-status --verbose` before/after on all
three hosts, verify ordinary host Internet/SSH, and confirm blocked IPv4/IPv6 and
DNS from retained isolated sessions throughout each outage.

| Approved exercise | Expected observation |
| --- | --- |
| PC reboot, then laptop reboot with gateway available | SOPS/transport start; isolated egress and registered app launch recover. |
| Client boot before gateway; delayed WAN/Tailscale/secrets | Clear prerequisite wait/configuration state; automatic retry once available. |
| Gateway reboot, then separately approved suspend/resume | Clients remain blocked, report peer uncertainty, recover after gateway prerequisites return; check sleep initiator. |
| Client/server WAN outage and restore | Host-layer diagnosis, no broad network restart, then automatic health restoration. |
| Stop/logout Tailscale or temporarily block shared UDP | Correct local/peer/handshake distinction; no inferred authorization failure. |
| Remove shared interface or fail relay in disposable/approved namespace | Only the proven component repaired; fresh isolated probes verify success. |
| Freeze provider or lose hm0/private resolvers | Debounced provider-only recovery with preserved filter and token state. |
| Confirmed auth rejection / recorded safe fixture | Manual-action hold and prompt launch error; never manufacture a live auth failure by rotating secrets. |
| Block one probe, then one family | Degraded status, no component restart; IPv4 readiness contract retained. |
| Exhaust repairs, set maintenance, and explicit reset | Counters/backoff persist; no restart storm or deliberate-stop override. |

Do not call mock coverage proof of real Hide.me recovery, lack of DNS leaks, or
real hardware reboot/resume behavior. Those remain deployment acceptance steps.
