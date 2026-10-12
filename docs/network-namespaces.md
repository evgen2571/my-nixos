# VPN agent workspace

Implementation is in progress on `feat/vpn-agent-workspace`. No VPN services or
application routing have been enabled yet. Existing Codex data and host networking
have not been changed.

## Package and compatibility gate

`packages/hide-me/default.nix` builds the official hide.me client at stable release
`v0.9.14`, commit `85463073f45872b6ab103fa7a007fd0672384d57`, with fixed source and
Go dependency hashes. The pinned stable nixpkgs Go toolchain satisfies upstream's
Go 1.24 requirement. The Arch packaging submodule is not needed to compile the
client. Upstream installation scripts are never executed. The package includes
upstream `CA.pem` and a default system CA bundle for DoH/server discovery.

hide.me negotiates WireGuard keys and addresses using its API. Free accounts do
not need static WireGuard configuration downloads. The client marks its API and
resolver sockets, and its kernel WireGuard socket, when `--firewall-mark` is set.
It does not spawn external processes for negotiation or tunnel configuration.

Source references:

- [Pinned README and installation instructions](https://github.com/eventure/hide.client.linux/blob/v0.9.14/README.md)
- [Configuration](https://github.com/eventure/hide.client.linux/blob/v0.9.14/configuration.go)
- [API sockets and token refresh](https://github.com/eventure/hide.client.linux/blob/v0.9.14/rest/client.go)
- [WireGuard setup](https://github.com/eventure/hide.client.linux/blob/v0.9.14/wireguard/wgLink.go)
- [Routing rules](https://github.com/eventure/hide.client.linux/blob/v0.9.14/wireguard/ipRule.go)
- [Routing tables](https://github.com/eventure/hide.client.linux/blob/v0.9.14/wireguard/ipRoute.go)
- [DNS writes](https://github.com/eventure/hide.client.linux/blob/v0.9.14/wireguard/dns.go)
- [Upstream systemd unit](https://github.com/eventure/hide.client.linux/blob/v0.9.14/hide.me%40.service)

### Isolation candidate under investigation

A persistent network namespace can use a `slirp4netns` TAP underlay instead of a
host veth/NAT configuration. Userspace NAT uses ordinary host sockets without
changing host routing, forwarding sysctls or firewall rules. Its built-in DNS and
host-loopback access must be disabled. This has a potential throughput cost; it
still needs a live hide.me tunnel test before becoming the production design.

An independent namespace `inet` nftables output policy drops traffic except for
loopback, the WireGuard interface, and marked TCP/UDP on the TAP. Ordinary
applications have neither CAP_NET_ADMIN nor CAP_NET_RAW and cannot set the
reserved socket mark. No blanket HTTPS, UDP, UID or established-output exception
is used. The policy covers both IP families and is installed before any app runs.
The upstream kill switch remains enabled as a second layer. It installs rules at
priority 10 and routes in table 55555; marked control/transport traffic bypasses
that table. These exceptions are protected by the independent nftables policy.

The hide.me process needs CAP_NET_ADMIN for interfaces, routes and socket marks.
The client itself needs no external executables. Its systemd notification is
optional; it can run without systemd in the compatibility probe. Slirp and any
namespace-entry helper have separate capability requirements.

The client writes `/etc/resolv.conf` in place and restores its previous contents
on shutdown. A private mount namespace must bind a writable resolver file over
that path for the client, and the same file must be exposed to launched apps.
`NetworkNamespacePath` alone does not provide this mount. The initial resolver
must point at inaccessible namespace loopback, with no host fallback. The client
fills in DNS addresses from the VPN response, including IPv6 when provided.
Host NSS is another boundary: the laptop has `nscd` and NSS `mymachines` /
`myhostname` sources. The probe binds a private `hosts: files dns` NSS
configuration and masks `/run/nscd`, preventing DNS lookups through host cache
IPC. Production launchers and the client must apply the same protection.

The mutable access-token file is rewritten on refresh. It must stay outside the
Nix store. Normal connections write no other required persistent state; DoH
resolver-list and resolver-backup files are optional. Do not use service mode's
control API for this deployment. Avoid saving generated configuration containing
credentials, enabling credential logging, or printing token files.

### Running the focused gate

Run all Nix commands on native `nixos-lp`, never through WSL's Nix daemon. A
separate checkout at `~/dev/my-nixos-vpn-test` preserves the original checkout.
Its base commit currently has the same tracked tree as the local feature branch
base. Synchronize new files explicitly; add them to the test checkout's index
before flake evaluation, because untracked files are excluded from Git flakes.

Build the client using the **pinned** stable nixpkgs path from `nix flake archive
--json --no-write-lock-file`, for example:

```bash
nix-build --no-out-link -E 'let p = import /nix/store/PINNED-NIXPKGS-source {}; in p.callPackage ./packages/hide-me {}'
nix-build --no-out-link -E 'let p = import /nix/store/PINNED-NIXPKGS-source {}; in p.symlinkJoin { name = "hide-me-probe-tools"; paths = with p; [ slirp4netns iproute2 nftables wireguard-tools curl coreutils util-linux ]; }'
bash tests/network-namespaces/compatibility.sh CLIENT_STORE_PATH TOOLS_STORE_PATH
```

The gate needs no sudo. It creates temporary user, network and mount namespaces;
sets up slirp; binds a private resolver; and installs only namespace-local nft
rules. It checks missing/invalid tokens, an unreachable endpoint, Free server
discovery, WireGuard kernel support, and application IPv4/IPv6 blocking. IPv6 has
an explicit test route so isolation does not rely on a missing default route.
The test drops all capabilities for app probes. Exit cleanup kills temporary
processes; it changes no host interfaces or firewall state. Successful completion
also compares host routes and resolver contents before/after. This proves only
the gate's tested topology, not a future service/launcher integration.

The optional third argument is an existing mode-0600 token file owned by the
invoking user; the fourth selects a Free server (default `free-nl`). The live gate
compares host/VPN egress, checks DNS, reports IPv6 availability, and probes failures
after DNS loss, tunnel deletion and client crash. It may refresh that token file.
Do not run concurrent clients sharing mutable token state.

### Initial authentication

In a private terminal **on the laptop**, use the Nix-built client:

```bash
umask 077
mkdir -p ~/.local/state/hide-me-bootstrap
cd ~/.local/state/hide-me-bootstrap
CLIENT_STORE_PATH/bin/hide.me --tokenFile "$PWD/accessToken.txt" token free-nl
```

Enter account credentials at the client's terminal prompts. Never pass a password
as an argument or paste credentials into chat. The token command only requests a
token; it does not create a tunnel or change routing/DNS. Upstream sometimes exits
zero on errors, so check its non-sensitive diagnostic and file existence rather
than trusting exit status alone. This is temporary user-owned bootstrap state;
production state must be migrated to a root-owned persistent service directory.
Each host needs its own state. Declarative packages/services cannot eliminate
initial secret provisioning.

## Implementation checkpoint

Verified on `nixos-lp` (kernel 7.2.6): native package build, real WireGuard
creation/cleanup, Free server discovery using marked sockets, and capability-free
IPv4/IPv6 blocking with no VPN, a missing token, an invalid token (API HTTP 401),
and an unreachable endpoint (request timeout). Host routes and resolver contents
were unchanged. The focused probe runs without sudo. The package has no upstream Go
tests; compilation is not evidence of a working VPN.

Pending in sequence:

1. Validate live Free-account tunnel compatibility using the bootstrap token.
   Authenticate manually if absent. The optional live probe has not yet run.
2. Implement persistent namespace, restricted slirp underlay, private DNS mounts,
   client service and readiness checks. Verify lifecycle and independent failure
   isolation. Obtain approval before any potentially disruptive activation;
   schedule session-independent rollback first. Remote sudo needs user assistance.
3. Implement a narrowly authorized namespace-entry launcher that drops privileges
   before Codex, preserves cwd/arguments/terminal/environment/signals, and refuses
   missing/unready namespaces. Test app-server and child inheritance.
4. Integrate Codex and the existing untracked `modules/user-ai/t3-code.nix`.
   Stable nixpkgs has T3 Code 0.0.24; pinned Home Manager has `programs.t3code`
   and mutable settings merges. Version 0.0.24 source confirms `binaryPath`,
   `homePath`, empty `shadowHomePath`, both provider settings locations, and
   `T3CODE_DISABLE_AUTO_UPDATE`. Its runtime/probe starts the configured binary
   with `app-server`. The unfinished module currently expects a Codex `package`
   option that is not yet implemented. Still verify desktop launch, executable
   selection and state preservation at runtime.
5. Enable both host profiles; build `.#nixos-lp` and `.#nixos-pc` on the laptop.
   Only test laptop activation. Preserve VPNBook and unrelated applications.
6. Replace this checkpoint with final operational service, launcher, recovery,
   fresh-install and troubleshooting instructions. Record actual verification
   gaps, including graphical and PC runtime checks.

No full NixOS build, live VPN, Codex namespace or T3 Code integration acceptance
has been established. No system generation has been activated for this work.
