# Shared Hide.me gateway

The profiles select one provider on `nixos-server` and namespace clients on
`nixos-pc` and `nixos-lp`. These are build-time selections, not live state.
Do not activate this migration without approval. Existing desktop tokens and the
standalone provider implementation are retained for rollback.

```text
codex / orca-vpn → client vpn namespace → shared0
  → WireGuard UDP over host Tailscale → server vpn/shared0
  → namespace forwarding + masquerade → Hide.me hm0 → slirp tap0 → Internet
```

Normal Orca remains on the host so its plain `ssh server` integrations continue
to work. Use `orca-vpn` explicitly for an isolated instance; all its children
inherit the VPN namespace and cannot directly reach host Tailscale SSH. Orca may
reuse an existing GUI process: close that instance before testing `orca-vpn` and
check the resulting process namespace. Codex remains wrapped by default.

## Transport choice

We evaluated reusing the existing Tailscale daemon alone. Its exit-node feature
routes traffic at the device level; preserving host networking would require
extra source/interface policy routing and server host forwarding into `vpn`.
A userspace SOCKS/HTTP proxy requires application support or another TUN adapter
to cover all subprocesses, protocols and isolated DNS. A separate namespace
Tailscale daemon would need another tailnet identity and authentication lifecycle.

Instead, a small kernel WireGuard interface is born in the **host** namespace
and moved into `vpn`. Its UDP socket keeps using host networking, including
Tailscale. This adds a public-key exchange and another encryption layer, but
avoids host forwarding, host NAT, exit-node settings, global routes, extra
Tailscale identities, proxy configuration, and a new data-plane dependency.
See [WireGuard namespace routing](https://www.wireguard.com/netns/),
[Tailscale exit nodes](https://tailscale.com/docs/features/exit-nodes) and
[userspace networking](https://tailscale.com/docs/concepts/userspace-networking).

Only UDP 51877 is opened on server `tailscale0`. Tailnet policy must allow the
PC and laptop to reach that port; WireGuard additionally authenticates each peer
and limits its source IPs to its assigned /32 and /128. The endpoint is the
observed server Tailscale IPv4 `100.96.206.10:51877`; update the profiles if it
changes. No LAN/public endpoint or subnet advertisements are configured.

## Isolation and services

The existing namespace setup, DNS/NSS mounts, privileged fixed-app launcher,
capability drop, `no_new_privs`, health timer and readiness TTL are reused.
Clients have no Hide.me or slirp service: their only default routes are through
`shared0`. The client local check requires the transport service, both route
families, the nft filter, recent WireGuard handshake and private resolver.
Its HTTPS probe must also succeed through the gateway within 90 seconds.

The server retains the existing Hide.me token/state, kill switch, slirp transport,
reconnection and health checks. Namespace forwarding allows only `shared0 → hm0`
and established replies in the opposite direction; namespace NAT covers both
IPv4 and IPv6. There is no forwarding fallback to `tap0`. A priority-9 destination
rule sends `10.77.0.0/24` and `fd77::/64` replies back to clients before Hide.me's
priority-10 routing table. No host routing or forwarding sysctls change.

`netns-vpn-dns` listens only inside the gateway on `10.77.0.1`, accepts DNS from
`shared0`, ignores host hosts files, disables caching, and polls Hide.me's private
resolver file. Upstream DNS can leave only through `hm0` (or loopback while
unready). Clients bind their private resolver pointing to `10.77.0.1`; host NSS
cache IPC remains masked by the launcher. On provider loss, existing processes
stall, new launches fail readiness checks, and DNS cannot use the host resolver.

`netns-vpn-shared` generates a persistent mode-0600 private key under its mode-0700
`/var/lib/netns-vpn-shared` directory. Private keys never enter Nix expressions,
Git, process arguments or logs. Peer public keys are runtime files in the same
directory. Startup refuses missing peers and retries every ten seconds. It does
not overwrite an existing private key. Back up private state privately if needed.
Missing transport does not create an alternate route. Provider crashes and short
underlay outages retain the existing reconnection logic; transport handshakes
resume after Tailscale connectivity returns. Actual suspend/resume needs live
verification. The server night-suspend timer is disabled while its gateway role
is selected; the wake timer is retained. Gateway availability then depends on
server power, networking and manual suspend decisions.

The fixed internal network is `10.77.0.0/24`, `fd77::/64` with server `.1`/`::1`,
PC `.2`/`::2`, laptop `.3`/`::3`, and MTU 1280. Do not reuse these ranges on other
namespace links. `shared.role = "standalone"` (the default) preserves the old
local Hide.me implementation. The role, client addresses, endpoint and peer
public-key paths live under `my.system.services.networkNamespaces.namespaces.vpn.shared`.
Only public-key paths are configured; secret contents must remain runtime state.

## Required host-side inspection

This Codex session is inside `vpn` with `no_new_privs`; it cannot reach server
Tailscale or elevate privileges. Use Orca's host terminal or a normal terminal
on `nixos-pc` to collect the following **read-only** output:

```bash
ssh server 'hostname; systemctl is-active tailscaled sshd hide-me-vpn netns-vpn; ip -brief address; ip route; ip -6 route; systemctl list-timers --all --no-pager'
ssh server 'sudo -n test -s /var/lib/hide-me-vpn/accessToken.txt && echo token-present || echo token-absent-or-sudo-unavailable'
ssh server 'sudo -n docker ps --format "{{.Names}} {{.Ports}}"'
systemctl is-active hide-me-vpn netns-vpn tailscaled
```

Do not print token contents, private keys, environment dumps or full WireGuard
configurations. The laptop must be online for simultaneous real-client testing.
A host-side execution session with ordinary `ssh server` and authorized sudo is
needed for approved deployment; do not bypass this session's security settings.

## Reversible migration (approval required)

1. Build all outputs and run the disposable namespace test below. Record all
   output paths and the old `/run/current-system` on each host. Finish the server
   audit, check its storage/SSH/Tailscale/Docker state, and bring the laptop online.
   Do not activate or stop a working local VPN during these steps.
2. Provision **only** WireGuard runtime keys without starting services. On each
   host, in a root host terminal with `wg` available:

   ```bash
   install -d -m 0700 /var/lib/netns-vpn-shared
   (umask 077; test -s /var/lib/netns-vpn-shared/private-key || wg genkey > /var/lib/netns-vpn-shared/private-key)
   wg pubkey < /var/lib/netns-vpn-shared/private-key > /var/lib/netns-vpn-shared/public-key
   ```

   Transfer public keys through host SSH: install the server public key as
   `server.pub` on each client; install PC/laptop public keys as `pc.pub` and
   `laptop.pub` on the server. Root-owned mode 0600 is sufficient. Verify keys
   match the intended machines. Never copy private keys. Provision a server
   Hide.me token using the existing private interactive bootstrap procedure in
   `network-namespaces.md`; token acquisition alone does not start a connection.
   Do not share a mutable desktop token with the server.
3. Obtain explicit approval for the staged cutover. **One active connection and
   live provider verification before disconnecting the current provider cannot
   both be achieved.** Offline transport/filter tests are the prerequisite; live
   Hide.me verification requires an approved exclusive handover with a short
   outage. Do not start the server provider while any desktop provider is active.
4. Copy the built server closure with `nix copy --to ssh://server SYSTEM_PATH`
   from a host terminal. Before server activation, run
   `sudo tests/network-namespaces/prepare-shared-rollback.sh SYSTEM_PATH SSH_PEER_IP`
   on the server. This records route/resolver state and roots the old system,
   then arms a root systemd rollback timer independent of SSH. It does **not**
   activate anything. Verify the timer is active. Use `test`, never `switch`,
   for the first activation so the boot generation stays unchanged.
5. Stop desktop Hide.me providers only after approval for the exclusive handover.
   Confirm PC and laptop providers are inactive. Temporarily mask them on both
   desktops to prevent accidental old-generation reconnection. Activate the
   approved server candidate with `SYSTEM_PATH/bin/switch-to-configuration test`.
   On failure, stop server Hide.me, run its recorded old generation with `test`,
   confirm the server provider stopped, then unmask/restart the previous PC VPN.
6. Verify server host SSH/Tailscale, Docker health, unchanged host routes/resolver,
   gateway VPN egress/DNS and kill switch. With its rollback still armed, prepare
   each client rollback and activate its matching built output with `test`.
   Namespace units deliberately survive rebuilds: the local-to-shared migration
   needs a controlled stop of health timer, provider, underlay and namespace,
   followed by start of namespace, shared transport and health timer. This ends
   existing app sessions; close/save them first. Do not restart NetworkManager,
   SSH or Tailscale. Verify each client's fresh namespace/filter and shared routes.
7. Perform the live checklist below before cancelling any rollback. For manual
   rollback, stop server Hide.me and restore the server first; then restore client
   generations. Client automatic rollback intentionally **masks** local Hide.me
   rather than starting another connection while the server might still run.
   Confirm server provider inactive before unmasking/restarting one desktop VPN.
   Existing tokens are retained. Restore the old namespace with a controlled
   restart; ordinary generation switching alone does not replace retained filters.
8. Only after all checks pass, cancel `shared-vpn-rollback.timer` on each host,
   then persist the reviewed configuration with a separately approved `switch`.
   Remove rollback snapshot roots when no longer needed. Never cancel a timer
   because SSH alone still works. A boot of the old generation is a recovery
   option, but avoid booting a desktop local provider while the gateway runs.

## Verification

Run the disposable integration test and builds without activation:

```bash
nix flake check
nix run .#shared-vpn-test
nix build --no-link .#nixosConfigurations.nixos-server.config.system.build.toplevel
nix build --no-link .#nixosConfigurations.nixos-pc.config.system.build.toplevel
nix build --no-link .#nixosConfigurations.nixos-lp.config.system.build.toplevel
```

The test uses disposable user/mount/network namespaces and the generated init and
transport scripts. It models Tailscale transport with local host UDP and Hide.me
with a separate mock egress namespace, tests simultaneous clients, both address
families, private DNS, failed VPN/transport and recovery, and compares host routes
and resolver. It does not authenticate to Hide.me or modify live networking.

Live acceptance remains distinct and must run through host SSH after approval:

- Compare PC/laptop simultaneous wrapped probe egress with server namespace
  egress and ordinary host egress. Register an immutable probe executable using
  the existing application registry; never authorize arbitrary privileged shells.
- Verify `codex exec`, resume and child namespace inheritance; verify `orca-vpn`
  process namespace and egress with no previously running host Orca instance.
- Check resolver mounts/NSS and DNS packets: client queries go to `10.77.0.1`,
  gateway upstream queries go through `hm0`, and none go through host resolver,
  host nscd or unmarked `tap0`. Use packet captures from host root terminals.
- While probes run, stop server Hide.me, remove its tunnel, simulate failed DNS,
  interrupt slirp and interrupt Tailscale in a way that preserves a recovery
  console. Both IPv4 and IPv6 must fail closed; no app should use host egress.
  Check restoration/reconnect and readiness expiry/refusal after each fault.
- Compare full host routes/rules and resolver checksums with snapshots. Maintain
  separate host SSH sessions throughout; test Docker services, host browsing and
  update access during VPN loss. Check suspend/reconnect separately if manual
  suspend is expected. Do not claim any of these passed based on mock tests.

## Implementation checkpoint

Non-activating builds for all three hosts, `nix flake check`, ShellCheck and the
disposable integration test passed on the PC. The disposable test uses mock
transport/egress and explicitly reapplies mock provider state on recovery.
No host configuration was activated, no local provider was stopped, and no keys
or credentials were provisioned. Server live inspection, real Hide.me/Tailscale
acceptance and production application/SSH/Docker checks remain pending the
host-side access and approval described above. Build results and test logs are
local `/tmp/shared-vpn-{build-server,build-pc,build-lp,flake-check,test}.log` files;
these are evidence for this session, not durable deployment state.
