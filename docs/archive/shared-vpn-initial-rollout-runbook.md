# Archived: shared VPN initial rollout runbook

> Historical snapshot of the **previous** deployment and rollback documentation. It contains time-bound assumptions about first-time provisioning, approval, inactive services and pending live acceptance. **Do not follow these steps on the current hosts without a new operator-reviewed deployment plan and current-state checks.** Use [the active gateway guide](../guides/shared-vpn-gateway.md) and [the networking agent guide](../../.agents/networking.md) for current architecture and diagnosis.

---

# Server-only Hide.me gateway

`nixos-server` is the only Hide.me provider. PC/laptop `vpn` namespaces route
selected applications over WireGuard carried by the existing host Tailscale
connection. There is no desktop provider, slirp underlay or local fallback.
If the server, transport, VPN or DNS fails, selected applications fail closed;
host browsing, SSH, updates, Docker and ordinary Orca retain regular networking.

```text
codex / orca-vpn → desktop vpn/shared0 → host Tailscale
  → server vpn/shared0 → namespace forwarding/NAT → Hide.me hm0
  → existing restricted slirp tap0 → Internet
```

Normal Orca stays on the host for its plain `ssh server` integrations. Use
`orca-vpn` explicitly for an isolated instance; close an existing ordinary Orca
instance first so its single-instance behavior cannot reuse a host process.
All isolated application children inherit the namespace, DNS mounts, capability
drop and `no_new_privs`. The launcher does not authorize arbitrary root commands.

## Declarative configuration and secrets

Profiles select client addresses `.2`/`fd77::2` on PC, `.3`/`fd77::3` on laptop,
and gateway `.1`/`fd77::1` in `10.77.0.0/24`, `fd77::/64`. MTU is 1280.
The endpoint `192.0.2.10:51877` is a **redacted documentation placeholder**, not
an actual or verified Tailscale endpoint. Get the operational endpoint from the
current private host overrides before diagnosing or deploying the gateway. The
server's `tailscale0` firewall and tailnet policy must permit the actual peer
traffic. WireGuard additionally authenticates peers and limits source prefixes.
Peer-key associations now live in the private host overrides; the former
`hosts/vpn-public-keys.nix` was removed by the personal-metadata split.

| Host | Encrypted SOPS file | Runtime secret |
| --- | --- | --- |
| PC | `secrets/vpn/pc.yaml` | `/run/secrets/vpn-wireguard-private-key` |
| Laptop | `secrets/vpn/laptop.yaml` | `/run/secrets/vpn-wireguard-private-key` |
| Server | `secrets/vpn/server.yaml` | WireGuard private key and `/run/secrets/hide-me-bootstrap-token` |

Each file is encrypted to that host's existing age recipient and the admin;
other host identities are not recipients. Private keys have been generated and encrypted;
the module never generates keys at boot. No plaintext private key is committed
or put into the Nix store. sops-nix decrypts root-only mode-0400 runtime files and
restarts the relevant service when a secret changes. There is no manual public-key
exchange. See [SOPS workflow](../reference/secrets.md) for identities and private editing.

**Server authentication is intentionally not provisioned yet.** Its
`hide_me_bootstrap_token` entry is empty; this is not a working credential.
The gateway refuses to start with an empty secret, even if an unrelated old
mutable token exists. An authorized administrator must set a real token through
SOPS before initial gateway activation:

```bash
nix shell --inputs-from . nixpkgs#sops -c sops secrets/vpn/server.yaml
```

Use a trusted private editor/session with the admin age identity. Enter the token
only in the editor; never use shell arguments, chat, Git plaintext or Nix strings.
Obtain it using the token-only interactive procedure in
[namespace primitives](../reference/network-namespaces.md). Confirm SOPS recipients against the
hosts' existing `/var/lib/sops-nix/key.txt` public identities; do not replace host
age identities or print their private contents. No current admin identity was
available to this agent, so real authentication requires that manual step.

The provider copies the SOPS seed into mode-0600 mutable state under
`/var/lib/hide-me-vpn`, because Hide.me refreshes its token in place. A protected
bootstrap digest prevents ordinary rebuilds/reboots from overwriting refreshed
authentication. Changing the SOPS token intentionally replaces the seed on the
next service start; sops-nix requests that restart automatically.

## Isolation and automatic lifecycle

The server preserves the existing Hide.me kill switch, restricted marked slirp
API/WireGuard transport, private DNS/NSS mounts, health checks and reconnection.
The only namespace forwarding path is `shared0 → hm0` plus established replies;
namespace NAT covers IPv4 and IPv6. Priority-9 destination rules return traffic
to clients before the provider's priority-10 table. There is no host NAT,
forwarding sysctl, exit-node setting or host default-route change.

Desktop output filters allow only loopback and `shared0`; they do not allow
`hm0`, marked `tap0`, or any underlay fallback. Their only IPv4/IPv6 defaults use
`shared0`. Existing readiness checks require service/filter/routes/handshake,
isolated DNS and a recent HTTPS probe. Server loss blocks new launches and
stalls existing sockets without changing the host network.

`netns-vpn-dns` is an unprivileged namespace-only DNS relay to the provider's
private resolver. It has no cache or host hosts-file fallback. It follows
resolver-file changes and transport restarts. It requires the namespace and is
ordered after a successful transport setup marker; depending directly on an
auto-restarting transport would bypass its retry delay. All app DNS mounts and
nscd masking remain in place.

Ordinary rebuilds and boots install secrets and start the required units
without manual starts, generated keys or namespace teardown commands. Changes to
managed shared namespace units restart them automatically; save/relaunch running
isolated applications when that network configuration changes. Routine app-only
rebuilds do not replace unchanged namespace units. WireGuard reconnects after
Tailscale returns; a recreated transport may need a fresh handshake before
health/readiness succeeds. The gateway profile disables nightly server suspension
and retains the morning wake timer. Manual server suspension makes clients
unavailable and must be tested with a recovery console.

## Permanent desktop disable

Client activation installs persistent masks for **both** `hide-me-vpn.service`
and `netns-vpn-underlay.service` in `/etc/systemd/system.control/`, which has higher
priority than generation-managed unit files. It stops both services when systemd
is running. During early boot activation, it writes the masks before systemd
starts; no daemon commands are needed then. Masks survive reboot into old NixOS
generations, including old laptop SOPS token provisioning. They are not removed
on rollback, and the helper has no unblock/provider-restoration mode.

The generic standalone provider code remains only as a reusable server primitive
and for old-generation regression tests. Neither desktop profile deploys it,
installs the Hide.me executable, or provisions a Hide.me token. An unused encrypted
historical laptop token may remain in its old SOPS document; it is not declared, installed or consumed by the new profile.

## Initial deployment (explicit approval required)

All actions below are pending; builds and tests never perform them on real hosts.

1. Privately provision the server SOPS token, build all three matching outputs,
   and bring both desktops online. Record old `/run/current-system`, routes,
   rules, resolver checksums and server Docker health. Keep ordinary host SSH
   sessions and a recovery console; do not run deployment from isolated Codex.
2. After approval, permanently disable desktop providers **first**. From a
   reviewed checkout on each desktop:

   ```bash
   sudo bash modules/system-services/network-namespaces/migration/desktop-provider-guard.sh
   systemctl show hide-me-vpn.service netns-vpn-underlay.service -p LoadState -p ActiveState
   ```

   Both units must be masked and inactive on **both** desktops before server
   gateway activation. Selected apps may be unavailable until the clients and
   server are activated; normal host networking remains usable. An offline,
   unguarded desktop blocks gateway activation because an old boot could connect.
3. Copy the built server closure from a host terminal with
   `nix copy --to ssh://server SERVER_SYSTEM`. Copy the reviewed migration bundle
   too, or use a server checkout. Before remote activation arm independent rollback:

   ```bash
   sudo bash modules/system-services/network-namespaces/migration/prepare-rollback.sh SERVER_SYSTEM SSH_PEER_IP
   systemctl is-active shared-vpn-rollback.timer
   sudo SERVER_SYSTEM/bin/switch-to-configuration test
   ```

   Server sudo requires an operator password. The helper only arms a root
   20-minute timer, roots the old generation and records snapshots; it never
   activates the candidate. The rollback uses the old generation's executable
   and PATH, with a five-minute service timeout, independent of SSH.
4. Check server host SSH/Tailscale/Docker and VPN readiness. Arm rollback on each
   desktop using its matching built path and activate with `test` in the same way.
   The client activation installs guards, replaces old namespace policy, loads
   SOPS keys and starts transport automatically; do not manually restore a local
   provider or underlay. Run the live checklist below before cancelling timers.
5. On failure, run `sudo systemctl start shared-vpn-rollback.service`, or let its
   timer fire. It cancels the timer, stops probes/provider/DNS/transport/underlay,
   disconnects retained namespace links, clears runtime resources and restores the
   old generation. Server lifecycle units are restored when present. Desktop
   rollback preserves both permanent masks and leaves its VPN namespace stopped;
   it restores host access, **never** a desktop VPN fallback. Reapply a corrected
   client generation to restore selected apps. Existing app processes holding an
   old namespace lose shared egress and must be relaunched.
6. After live acceptance, cancel rollback timers and persist the reviewed
   generation with an approved `switch`. Keep desktop masks permanently. Remove
   obsolete rollback snapshot roots when no longer needed.

## Verification and pending live acceptance

```bash
nix flake check
nix run .#shared-vpn-test
nix build --no-link .#nixosConfigurations.nixos-server.config.system.build.toplevel
nix build --no-link .#nixosConfigurations.nixos-pc.config.system.build.toplevel
nix build --no-link .#nixosConfigurations.nixos-lp.config.system.build.toplevel
```

The native test uses disposable namespaces, public mock key seeds and generated
scripts to check simultaneous IPv4/IPv6 clients, DNS, missing private keys,
empty authentication, token refresh/seed rotation, failures and recovery. The VM
test exercises actual sops-nix decryption of runtime-created encrypted mock data,
normal client boot/reboot, automatic old-to-client activation, DNS and transport
restarts, independent retained-namespace rollback, and persistent provider **and
underlay** masks across an old-generation reboot. No real provider authentication
or live routing is involved.

After approval, perform these live checks from host terminals:

- `sudo /etc/network-namespaces/vpn-check` on all hosts; inspect route families,
  `wg show shared0 latest-handshakes`, the namespace nft filter and relevant units.
- Run `codex exec` simultaneously on PC/laptop to report `id`, namespace identity,
  resolver mounts and `curl --noproxy '*' -4/-6` public egress. Compare both with
  server namespace egress and ordinary host egress. Test Codex resume and an
  `orca-vpn` child; test normal Orca's plain SSH separately.
- In root host terminals, capture DNS with `tcpdump -ni shared0 port 53`,
  `tcpdump -ni hm0 port 53`, `tcpdump -ni tap0 port 53` inside the server namespace,
  and on host interfaces. Plain DNS must use client `10.77.0.1` and server `hm0`,
  with no host/underlay leak. Use a temporary pinned `nix shell` for tcpdump if needed.
- While both clients probe, stop/start server `hide-me-vpn`; restart its slirp
  underlay and shared transport separately. Simulate failed DNS by backing up
  and rewriting the gateway resolver **in place**, then restore it **in place**.
  Verify both families fail closed and recover. Test blocked Tailscale UDP or a
  removed tunnel only with a timed restore and independent recovery console.
- Compare host routes/rules/resolver hashes with snapshots throughout; verify
  `ssh server`, normal browsing/update access and the actual Docker service via
  its normal client during each fault. Health status alone is insufficient.
- Exercise armed rollback and guarded old-generation reboot. Both desktop local
  units must stay masked/inactive; selected apps remain unavailable until a valid
  client generation runs. Test server suspend/resume only with a local operator.

The previous read-only audit recorded host SSH over Tailscale, ordinary host
routing, Docker and provider state. Its endpoint addresses are redacted here:
`192.0.2.10` is **documentation-only**, not an operational host address. Consult
the private host configuration and independently verify actual addresses and
connectivity before deployment. Authentication and real egress/DNS/application/
fault acceptance remain pending. No live masks, timers, providers,
credentials or networking have been changed by implementation/build/test work.
