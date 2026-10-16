# Isolated VPN namespace primitives

Production uses one server Hide.me provider and desktop WireGuard-only clients.
See [server-only shared gateway](shared-vpn-gateway.md) for SOPS, permanent desktop
disable, automatic lifecycle, approved deployment and live acceptance. There is
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

The production server's bootstrap token is declared through sops-nix. Its entry
in `secrets/vpn/server.yaml` is currently empty and **must be provisioned** before
the gateway can authenticate. Do not reuse live desktop mutable token files.
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
token file; upstream may return zero on failure. Privately put that token into
`hide_me_bootstrap_token` using `sops secrets/vpn/server.yaml` with the admin age
identity. Commit only the encrypted document, and remove the temporary bootstrap
copy afterward. Never print the token or pass it as an argument/Nix value.

The server keeps a protected mutable token for provider refreshes. Unchanged
SOPS seeds preserve refreshes across boot/rebuild; changed seeds replace it on
service restart. Desktop profiles do not declare their old authentication secret.

## Readiness, recovery and application launch

Every launch checks active transport/provider, nft filter, both address-family
routes, recent WireGuard handshake and isolated resolver. A successful HTTPS
probe within 90 seconds is also required. The timer probes configured endpoints
every 30 seconds; a brief failed probe preserves the previous success only until
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
Normal Orca stays on the host for SSH; `orca-vpn` selects the isolated namespace.

To add another application, use the existing registry and launcher:

```nix
my.system.services.networkNamespaces.applications.mytool = {
  namespace = "vpn";
  user = "operator";
  package = pkgs.mytool;
};
# Wrapper: exec ${lib.getExe config.my.system.services.networkNamespaces.launcherPackage} mytool "$@"
```

Do not authorize a generic privileged shell as an application. Normal app children
cannot elevate through sudo/setuid because of `no_new_privs`. For approved host
inspection/deployment use a separate host terminal, never a namespace bypass.
