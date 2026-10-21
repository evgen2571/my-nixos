# VPN namespace internals

Use [VPN diagnosis](vpn.md) for ordinary incidents. This page covers the filter,
resolver and credential boundaries to preserve when changing the implementation.

## Routing and DNS

The server's `netns-vpn` creates the namespace, private resolver/NSS files and an
independent IPv4/IPv6 nft filter before networking. `netns-vpn-underlay` runs
slirp4netns with host loopback and its DNS proxy disabled. No host veth, NAT,
forwarding or default-route changes are needed. The pinned official Hide.me
v0.9.14 client runs inside `vpn`; its package never runs upstream installation or
update scripts.

| Interface | Role | Allowed traffic |
| --- | --- | --- |
| Server `tap0` | Restricted provider underlay | Provider TCP/UDP carrying mark `0x486d` |
| Server `hm0` | Hide.me tunnel | Provider egress and permitted shared-client forwarding |
| `shared0` | WireGuard over host Tailscale | Desktop-to-gateway traffic and replies |

Server output also permits loopback and shared-client replies. Only
`shared0 → hm0` and established replies may forward; never `shared0 → tap0`.
The provider marks API/DoH and WireGuard transport sockets. Capability-free apps
cannot set the mark. Keep both the independent nft filter and upstream
priority-10/table-55555 kill switch. Crash cleanup must not remove the filter.

The server bind-mounts its writable private resolver over `/etc/resolv.conf`.
Apps mount that file read-only, use `hosts: files dns`, and mask `/run/nscd` to
prevent host cache/NSS fallback. Desktop namespaces apply the same filesystem
isolation, with DNS through the gateway relay. Client output allows only loopback
and `shared0`, with no local provider or underlay fallback.

The public profiles use PC `10.77.0.2/24`, `fd77::2/64`, laptop `10.77.0.3/24`,
`fd77::3/64`, gateway `10.77.0.1/24`, `fd77::1/64`, and MTU 1280. Gateway peer
prefixes are `/32` and `/128`. Private overrides supply real endpoints and peer
keys. Addresses in configuration do not prove current reachability.

## Private server authentication

SOPS supplies the server bootstrap token and each host's WireGuard private key.
A missing/empty runtime secret blocks startup. Never inspect or print its values;
verify provisioning through protected-path metadata and health checks. Historical
desktop mutable token files must not become a fallback.

Only when credential renewal is confirmed necessary, build the client from a
private host terminal without activation:

```bash
nix build --impure --no-link --print-out-paths --expr 'let f = builtins.getFlake (toString ./.); p = import f.inputs.nixpkgs { system = "x86_64-linux"; }; in p.callPackage ./packages/hide-me {}'
```

Replace `CLIENT_STORE_PATH` with the printed store path. Token-only login creates
no VPN connection and changes no routes/DNS:

```bash
umask 077
mkdir -p ~/.local/state/hide-me-bootstrap
cd ~/.local/state/hide-me-bootstrap
CLIENT_STORE_PATH/bin/hide.me --tokenFile "$PWD/accessToken.txt" token free-nl
```

Enter credentials only at interactive prompts. Confirm that the protected file is
nonempty without printing it; upstream may return zero on failure. In the
repository owning the server ciphertext, use the protected admin identity and
`sops secrets/hosts/server.yaml` to update only `hide_me_bootstrap_token`. Commit
only ciphertext, then remove the temporary bootstrap copy. Never pass the token
as an argument or Nix value.

The provider preserves refreshed mutable tokens when the SOPS seed is unchanged.
A changed seed replaces the mutable token on service restart. Do not replace a
valid refreshed token with an old seed. A rejected authorization hold survives
reboots; follow [hold review and reset](vpn.md#maintenance-and-authorization-holds)
before an approved restart. HTTP 401/403 establishes rejection, not expiry.

## Add an isolated application

Use the existing immutable application registry in
[launcher.nix](../../modules/services/network-namespaces/launcher.nix):

```nix
my.system.services.networkNamespaces.applications.mytool = {
  namespace = "vpn";
  user = config.my.primaryUser.name;
  package = pkgs.mytool;
};
# Wrapper: exec ${lib.getExe config.my.system.services.networkNamespaces.launcherPackage} mytool "$@"
```

Never register a generic privileged shell. The launcher accepts only its fixed
application and authorized normal user. It preserves arguments, environment,
cwd, stdio, signals and exit status through a sealed environment descriptor,
enters network/mount namespaces, restores groups, drops root IDs/capabilities,
sets `no_new_privs`, closes extra descriptors and executes the app. Children
cannot regain privilege through sudo/setuid. This isolates networking; connected
host UNIX services can still do work on the host. Use a separate normal host
terminal for administration.

Every launch checks units, nft policy, both family routes, handshake and resolver,
plus the 90-second IPv4 HTTPS readiness marker. [Recovery](vpn.md#automatic-recovery)
runs isolated probes; a marker never bypasses current local checks.

For Codex authentication, use `codex login --device-auth`; a host browser cannot
reach a namespace-loopback OAuth callback. Codex state remains mutable. The VPN
wrapper defaults `my.user.ai.codex.httpOnly = true` to use HTTP Responses because
streaming WebSockets repeatedly reconnected over this gateway while HTTPS worked.
It defaults to true only with `networkNamespace`; false restores upstream
transport selection. Authentication, MCP and ordinary arguments are unchanged.
Normal Orca uses the host; `orca-vpn` opts into isolation.

## Diagnostic data

`/var/lib/network-namespaces-vpn/status.json` exposes sanitized snapshots to local
users. `probes.json` stores numeric exit codes/timestamps; the gateway DNS relay
probe records `relay_dns.exit_code` and `relay_dns.answered`. Missing/nonexecutable
DNS tools yield UNKNOWN without consuming a relay repair attempt. Fixed journal
fields include `VPN_REASON`, `VPN_PHASE` and `VPN_ATTEMPTS`. Provider text,
resolver contents and credentials stay out of public diagnostics.

`hold.json` and boot-tagged per-unit `stops/` records are private root-owned
recovery state, not tokens. Preserve them during diagnosis. The reset helper
clears holds/counters without touching token files; the existing preparation
script alone decides when a changed bootstrap replaces mutable credentials.
