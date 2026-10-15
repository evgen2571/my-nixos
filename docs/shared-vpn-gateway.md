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
observed server Tailscale IPv4 `192.0.2.11:51877`; update the profiles if it
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
directory. Startup refuses missing peers and retries every ten seconds. It publishes public keys atomically and does
not overwrite an existing private key. Back up private state privately if needed.
Client activation installs a persistent `/etc/systemd/system.control/hide-me-vpn.service`
mask. This directory has higher priority than the generation-managed unit tree
and survives reboot into pre-migration generations, including laptop SOPS token
reprovisioning. Normal `systemctl unmask` does not remove this guard. Explicit
`vpn-desktop-provider-guard unblock` is required after the gateway is confirmed
stopped. Installing the guard does not stop an already running provider.

Missing transport does not create an alternate route. Provider crashes and short
underlay outages retain the existing reconnection logic; transport handshakes
resume after Tailscale connectivity returns. Gateway transport recreation also
restarts its bound DNS unit. DNS is ordered after transport and gated by a root-owned transport-setup
marker; it requires the namespace rather than the auto-restarting transport,
so missing peer keys respect the transport retry delay instead of causing a
dependency restart loop. Namespace restarts propagate to transport, underlay
and provider units. A fresh transport can require a new WireGuard handshake;
recovery is not instantaneous and readiness checks stay fail-closed meanwhile. Actual suspend/resume needs live
verification. The server night-suspend timer is disabled while its gateway role
is selected; the wake timer is retained. Gateway availability then depends on
server power, networking and manual suspend decisions.

The fixed internal network is `10.77.0.0/24`, `fd77::/64` with server `.1`/`::1`,
PC `.2`/`::2`, laptop `.3`/`::3`, and MTU 1280. Do not reuse these ranges on other
namespace links. `shared.role = "standalone"` (the default) preserves the old
local Hide.me implementation. The role, client addresses, endpoint and peer
public-key paths live under `my.system.services.networkNamespaces.namespaces.vpn.shared`.
Only public-key paths are configured; secret contents must remain runtime state.

## Host-side inspection checkpoint

On 2026-10-15 a separate Orca host terminal, network namespace `4026531833`,
ran plain `ssh server` successfully. `SSH_CONNECTION` confirmed the transport
from PC Tailscale `192.0.2.10` to server `192.0.2.11:22`. This Codex session remained in namespace
`4026532702`; no `setns`, privilege escalation or `no_new_privs` change was used.
The server itself reported `nixos-server`, Tailscale IPv4 **192.0.2.11**,
active SSH/Tailscale, no active Hide.me/namespace service, ordinary default route
via `192.168.1.1`, and a healthy Docker container. PC default routing also remained
ordinary, and its existing namespace/provider stayed active. The server still has
its night-suspend timer enabled; candidate activation disables that timer.

Server `sudo -n` requires a password. Token presence is **unknown**, not absent.
An operator must check privately from a host terminal:

```bash
ssh -t server 'sudo bash -c "if test -s /var/lib/hide-me-vpn/accessToken.txt; then echo token-present; else echo token-absent; fi"'
```

Repeat read-only inspection immediately before approved deployment:

```bash
ssh server 'hostname; tailscale ip -4; systemctl is-active tailscaled sshd; ip route; ip -6 route; ip rule; ip -6 rule; sha256sum /etc/resolv.conf; docker ps --format "{{.Names}} {{.Status}} {{.Ports}}"'
systemctl is-active hide-me-vpn netns-vpn tailscaled
```

Do not print tokens, private keys, environment dumps or full WireGuard
configurations. The laptop must be online for simultaneous real-client testing.
A host-side execution session with authorized sudo is needed for approved
migration. Keep a host terminal independent of Codex's namespace throughout.

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
   First install the persistent guard on **both** desktops from the reviewed
   checkout, then stop their providers:

   ```bash
   sudo bash modules/system-services/network-namespaces/migration/desktop-provider-guard.sh block
   sudo systemctl stop hide-me-vpn.service
   test "$(systemctl show hide-me-vpn.service -p LoadState --value)" = masked
   ! systemctl is-active --quiet hide-me-vpn.service
   ```

   Check both machines; an offline, unguarded laptop blocks migration because it
   could reconnect when it boots. This mask survives reboot into old generations
   and old laptop SOPS token provisioning. Do not use `--runtime` masks. Activate the
   approved server candidate with `SYSTEM_PATH/bin/switch-to-configuration test`.
   On failure, start its `shared-vpn-rollback.service` immediately or let the
   armed timer run. Confirm server Hide.me inactive before explicitly removing
   the persistent guard and restarting the previous provider on one desktop.
6. Verify server host SSH/Tailscale, Docker health, unchanged host routes/resolver,
   gateway VPN egress/DNS and kill switch. With its rollback still armed, prepare
   each client rollback and activate its matching built output with `test`.
   Namespace units deliberately survive rebuilds: the local-to-shared migration
   needs a controlled stop of health timer, provider, underlay and namespace,
   followed by temporary activation and an explicit start:

   ```bash
   sudo systemctl stop netns-vpn-health.timer netns-vpn-health.service hide-me-vpn.service netns-vpn-underlay.service netns-vpn.service
   sudo SYSTEM_PATH/bin/switch-to-configuration test
   sudo systemctl start netns-vpn.service netns-vpn-shared.service netns-vpn-health.timer
   ```

   Prepare each client's rollback **before** stopping its namespace. This ends
   existing app sessions; close/save them first. Do not restart NetworkManager,
   SSH or Tailscale. Verify each client's fresh namespace/filter and shared routes.
7. Perform the live checklist below before cancelling any rollback. For manual
   rollback, stop server Hide.me and restore the server first; then restore client
   generations using `sudo systemctl start shared-vpn-rollback.service`.
   The root oneshot cancels its timer to prevent a repeated manual rollback,
   uses the rooted old generation's executable and PATH,
   stops probes/provider/DNS/transport/underlay/namespace in order, removes any
   orphaned named namespace and VPN links, clears its runtime resources, switches
   to the old generation and explicitly starts its restored namespace lifecycle.
   Existing app processes can retain an old namespace, but its shared egress link
   is removed. They must be relaunched.

   Desktop rollback keeps the **persistent** provider guard. It does not assume
   that the server's rollback has already run and never starts a second provider.
   After confirming server Hide.me inactive, restore exactly one desktop provider:

   ```bash
   sudo bash modules/system-services/network-namespaces/migration/desktop-provider-guard.sh unblock
   sudo systemctl start hide-me-vpn.service netns-vpn-health.timer
   ```

   Existing tokens are retained. No guard is removed automatically, including
   during old-generation activation or reboot. A rollback failure leaves the
   guard installed; inspect `journalctl -u shared-vpn-rollback` from the host.
8. Only after all checks pass, cancel `shared-vpn-rollback.timer` on each host,
   then persist the reviewed configuration with a separately approved `switch`.
   Remove rollback snapshot roots when no longer needed. Never cancel a timer
   because SSH alone still works. A boot of the old generation is a recovery
   option: the persistent guard must remain installed on both desktops for as
   long as the gateway can run. Keep it after successful migration too.

## Verification

Run the disposable integration test and builds without activation:

```bash
nix flake check
nix run .#shared-vpn-test
nix build --no-link .#nixosConfigurations.nixos-server.config.system.build.toplevel
nix build --no-link .#nixosConfigurations.nixos-pc.config.system.build.toplevel
nix build --no-link .#nixosConfigurations.nixos-lp.config.system.build.toplevel
```

`nix flake check` includes a two-VM test with real systemd, generated units,
privilege-restricted DNS, a simulated old provider and mock transport/egress. It
checks missing-peer startup/retry, DNS resolver-file updates, DNS outage/recovery,
DNS restart with gateway transport, blocked UDP recovery, independent rollback
with an app retaining the old namespace, and an actual reboot into the old
standalone image whose activation does not install a guard. No real Hide.me
connection or credentials are involved. The guard must still block that image's
provider; the test records provider starts to detect unwanted reconnects.

The separate `shared-vpn-test` uses disposable user/mount/network namespaces and the generated init and
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

## Exact live acceptance steps (not yet run)

These commands require explicit networking-activation approval and the migration
steps above, including both persistent desktop guards, exchanged public keys,
a privately provisioned server token, and independent rollback on all three hosts.
Server sudo requires an operator's password. Do not enter it in agent messages.

1. Record the rollback snapshot path printed by each helper. Keep two host SSH
   sessions to the server and a local recovery console. Before activation and
   after every fault, compare `ip -4/-6 route show table all`, `ip -4/-6 rule show`,
   and `sha256sum /etc/resolv.conf` against those snapshots. Verify `ssh server`,
   `tailscale ping nixos-server`, `docker ps`/container health, normal browser
   access and `nix flake metadata --refresh` from host terminals. Exercise the
   actual Docker service with its normal client during each fault too. Health/timer
   status alone does not prove real egress or unaffected Docker traffic.
2. After the server/client temporary activation, run on each host:

   ```bash
   sudo /etc/network-namespaces/vpn-check
   systemctl status netns-vpn netns-vpn-shared netns-vpn-health.timer --no-pager
   sudo ip -n vpn route show table all
   sudo ip -n vpn -6 route show table all
   sudo ip netns exec vpn nft list table inet agent_workspace
   sudo ip netns exec vpn wg show shared0 latest-handshakes
   ```

   Additionally check server `hide-me-vpn`, `netns-vpn-underlay`, `netns-vpn-dns`
   and `server-night-suspend.timer` (the suspend timer must be disabled/inactive).
3. Simultaneously on PC/laptop, use the existing wrapped Codex to run an actual
   child command, then resume that session:

   ```bash
   codex exec 'Run id, readlink /proc/self/ns/net, cat /etc/resolv.conf, curl --noproxy "*" -4 --max-time 10 https://api.ipify.org, and curl --noproxy "*" -6 --max-time 10 https://api64.ipify.org. Report raw results.'
   codex resume
   ```

   Compare with server namespace and ordinary host egress from a root host
   terminal (`sudo ip netns exec vpn curl --noproxy '*' -4/-6 ...` versus ordinary
   `curl -4/-6 ...`). Both clients must share server VPN egress, distinct from host
   egress. Close any ordinary Orca instance, launch `orca-vpn`, repeat the child
   probes and verify its process namespace. Restart normal Orca and verify its
   existing plain SSH integration. Root probes alone cannot replace app tests.
4. Capture DNS on the gateway from separate approved root host terminals:

   ```bash
   nix shell --inputs-from . nixpkgs#tcpdump
   sudo ip netns exec vpn "$(command -v tcpdump)" -ni shared0 port 53
   sudo ip netns exec vpn "$(command -v tcpdump)" -ni hm0 port 53
   sudo ip netns exec vpn "$(command -v tcpdump)" -ni tap0 port 53
   sudo "$(command -v tcpdump)" -ni any port 53
   ```

   Query from both wrapped clients while checking their resolver/NSS mounts and
   masked nscd path. Plain DNS must use client `10.77.0.1` and server `hm0`; none
   may escape on the underlay or host. DoH bootstrap traffic is encrypted and is
   separately restricted by the provider mark, not observable as port-53 DNS.
5. With both client probes running, use host SSH to stop/restart only the server
   provider, then restart its underlay and shared transport separately:

   ```bash
   ssh -t server 'sudo systemctl stop hide-me-vpn'
   # Both client address families and DNS must fail; host SSH/Docker must work.
   ssh -t server 'sudo systemctl start hide-me-vpn'
   ssh -t server 'sudo systemctl restart netns-vpn-underlay'
   ssh -t server 'sudo systemctl restart netns-vpn-shared'
   ```

   Verify fresh readiness and DNS after each recovery. Also simulate invalid
   upstream DNS by backing up `/run/network-namespaces/vpn/resolv.conf`, writing
   only `nameserver 127.0.0.1` **in place**, verifying DNS/app failure, then restoring
   its original contents **in place** (bind mounts depend on the inode). Do not
   edit the token or host resolver. Test a removed tunnel and blocked Tailscale
   UDP only with a recovery console and an approved timed restore, preserving
   the SSH control path. Neither packet-family may fall back to host networking.
6. Test each armed rollback with `sudo systemctl start shared-vpn-rollback.service`,
   restoring the server first. Confirm restored namespace/filter/resolver and
   closed retained app namespace egress. Check desktop provider `LoadState=masked`.
   Re-apply a new approved test only after re-arming rollback. Reboot a guarded
   desktop into its old generation while the verified gateway remains active;
   confirm its provider never starts. Check server manual suspend/resume only
   with a local recovery operator. These destructive session tests end app
   connections and require their own explicit approval.
7. Only after all checks pass cancel rollback timers, persist the reviewed
   generations with an approved `switch`, and retain both desktop guards.

## Implementation checkpoint

Host-side SSH/address/Docker inspection succeeded through a separate Orca host
terminal; sudo token inspection requires a password. Live migration and all
acceptance steps above remain unperformed. No live provider, namespace, route,
mask or timer was changed. Automated test results and builds are recorded in
PR #12; mock tests do not establish real Hide.me/Tailscale acceptance.

Review verification passed: all three host builds, the real-systemd VM regression
test (including old-generation reboot and reversible guard), the disposable
simultaneous IPv4/IPv6/DNS/fail-closed test, formatting and ShellCheck. VM tests
use mocked provider and Tailscale transport; no live Hide.me acceptance is implied.
