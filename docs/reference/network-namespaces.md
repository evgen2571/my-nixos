# Isolated VPN namespace primitives

Production uses one server Hide.me provider and desktop WireGuard-only clients.
See [server-only shared gateway](../guides/shared-vpn-gateway.md) for SOPS, persistent desktop provider guards, lifecycle, current-state verification and approved deployment. There is
no desktop provider or fallback, including when rolling back to old generations.

## Server provider

`netns-vpn` creates the namespace, private resolver/NSS files and an independent
IPv4/IPv6 nft filter before networking starts. `netns-vpn-underlay` runs slirp4netns
inside the server architecture; host loopback access and its DNS proxy are off.
There are no host veth/NAT/forwarding/default-route changes. The pinned official
Hide.me v0.9.14 client runs inside `vpn` and negotiates Free WireGuard credentials.
The reproducible package never runs upstream installation/update scripts.

The server output policy accepts loopback, `hm0`, shared client replies, and only
TCP/UDP on `tap0` carrying reserved mark `0x486d`. The provider marks API/DoH and
kernel WireGuard transport sockets. Capability-free applications cannot set that
mark. The upstream priority-10/table-55555 kill switch remains enabled; stale
crash routing/tunnel state is cleaned up without removing the independent filter.
Only shared-client traffic may forward through `hm0`, never through `tap0`.

The provider bind-mounts its writable private resolver over `/etc/resolv.conf`.
Applications mount the same file read-only; all use `hosts: files dns` and mask
`/run/nscd` to prevent host NSS/cache DNS fallback. Client namespaces use the
same filesystem isolation with DNS pointing to the gateway. Client filters allow
only loopback and `shared0`, not provider or underlay interfaces.

## Private server authentication

The server declares its bootstrap token through sops-nix. The repository does **not** establish whether the protected runtime secret is currently provisioned on the host; verify service readiness through the approved private operator workflow, without printing or decrypting the token. A missing/empty runtime secret blocks authentication. Do not reuse historical desktop mutable token files.
In a private host terminal, build the client package without activation:

```bash
nix build --impure --no-link --print-out-paths --expr 'let f = builtins.getFlake (toString ./.); p = import f.inputs.nixpkgs { system = "x86_64-linux"; }; in p.callPackage ./packages/hide-me {}'
```

Replace `CLIENT_STORE_PATH` with its printed package path. Token-only login does
not create a VPN connection or change routing/DNS:

```bash
umask 077
mkdir -p ~/.local/state/hide-me-bootstrap
cd ~/.local/state/hide-me-bootstrap
CLIENT_STORE_PATH/bin/hide.me --tokenFile "$PWD/accessToken.txt" token free-nl
```

Enter credentials only at the interactive prompts. Confirm a nonempty private
token file; upstream may return zero on failure. For a genuinely unprovisioned server, privately put that token into
`hide_me_bootstrap_token` using `sops secrets/hosts/server.yaml` with the admin age
identity. Commit only the encrypted document, and remove the temporary bootstrap
copy afterward. Never print the token or pass it as an argument/Nix value.

The server keeps a protected mutable token for provider refreshes. Unchanged
SOPS seeds preserve refreshes across boot/rebuild; changed seeds replace it on
service restart. Desktop profiles do not declare their old authentication secret.

## Readiness, recovery and application launch

Every launch checks active transport/provider, nft filter, both address-family
routes, recent WireGuard handshake and isolated resolver. A successful HTTPS
probe within 90 seconds is also required. The shared recovery timer requests probes of configured endpoints
30 seconds after each completed run; a brief failed probe preserves the previous success only until
it expires. No marker bypasses fresh local checks. Default probes go to GitHub
and Cloudflare; success does not prove every application API works.

The restricted immutable app registry accepts only the authorized normal user
and fixed executable. The helper preserves environment through a sealed file
descriptor, enters network/mount namespaces, restores groups, drops all root IDs
and capabilities, sets `no_new_privs`, closes extra descriptors and execs the app.
Arguments, environment, cwd, stdio, signals and exit status are preserved. Codex
and local subprocesses share the namespace. Host UNIX services can perform work
on the host; this is networking isolation, not a sandbox against the machine owner.

Use `codex login --device-auth` for new authentication: a host browser cannot
reach a namespace-loopback OAuth callback. Existing Codex state remains mutable.
VPN-isolated Codex uses a wrapper-level HTTP Responses provider by default
(`my.user.ai.codex.httpOnly = true`) instead of WebSockets, because the default
streaming connection repeatedly reconnected over the shared gateway while HTTPS
worked. The option defaults to true only when `networkNamespace` is set; set it
to false to restore upstream transport selection. Authentication, MCP configuration,
normal CLI arguments and namespace fail-closed checks are unchanged.
Normal Orca stays on the host for SSH; `orca-vpn` selects the isolated namespace.

To add another application, use the existing registry and launcher:

```nix
my.system.services.networkNamespaces.applications.mytool = {
  namespace = "vpn";
  user = config.my.primaryUser.name;
  package = pkgs.mytool;
};
# Wrapper: exec ${lib.getExe config.my.system.services.networkNamespaces.launcherPackage} mytool "$@"
```

Do not authorize a generic privileged shell as an application. Normal app children
cannot elevate through sudo/setuid because of `no_new_privs`. For approved host
inspection/deployment use a separate host terminal, never a namespace bypass.

### Guarded recovery and diagnostic state

On the shared gateway and both clients, use `vpn-status` or `vpn-status --verbose`
from an ordinary host terminal. It is read-only and works without a desktop
session or sudo. It reports application readiness separately from the fail-closed
routing policy and scheduler activity. Readiness combines a recent verified
snapshot, the IPv4 marker and current unit/namespace presence; protected checks
still run at every launch. Failed registered launches always report BLOCKED,
even if a cached scheduled check succeeded. See the
[current recovery policy and reason codes](../guides/shared-vpn-gateway.md#resilience-and-day-to-day-diagnosis)
for retry bounds, maintenance, reset and a separately approved live test matrix.

The shared-role recovery oneshot requests the isolated health service rather
than probing application traffic from the host. Probe results contain only
numeric curl exit codes/timestamps; the public status contains fixed diagnoses,
unit properties and bounded failure history. Provider journal lines, resolver
contents and secret values are never copied into diagnostics. Client reports
remain local: inspect the server through the existing authenticated operator
channel to learn provider-specific evidence.

`/var/lib/network-namespaces-vpn/hold.json` is private root-owned recovery state,
not a token. The provider's `ExecCondition` respects an unchanged authorization
or rate-limit hold even across reboot. Review the cause before using
`sudo /etc/network-namespaces/vpn-recovery-reset`; it clears only the hold and
repair counters. A recorded operator stop still needs an explicit start; a
provider stopped by the doctor can resume through bounded recovery. Renewed
credentials must be tried in a fresh invocation: retained errors from the rejected
invocation cannot re-create the hold. The new invocation can establish a new
hold if it reports rejection. Unchanged seeds still preserve refreshed tokens.
A missing bootstrap, wrong generation or rejected authorization cannot be fixed
by rebuilding repeatedly or restoring an old seed over a valid mutable token.
401/403 proves rejection, not expiry; confirm the account/credential state
privately before following the bootstrap procedure above. The pinned client's
normal refresh behavior remains the only unattended token refresh mechanism.

Managed service hooks record running, direct-stop, dependency-stop and recovery
intent in root-owned per-unit `stops/` files tagged with the boot ID. They do not
rely on old start timestamps to identify an operator stop. A legacy inactive unit
without a record is conservatively `STOP_INTENT_UNKNOWN`; verify intent before
starting it. Use the explicit maintenance flag during concurrent operations.
Namespace/secrets startup waits have their own diagnoses, and firewall damage is
classified only after namespace readiness. Host HTTPS failure with a valid or
unknown route is `HOST_CONNECTIVITY_UNVERIFIED`, not proof of a WAN outage.
