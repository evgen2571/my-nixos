# VPN agent workspace

Both host profiles enable an isolated `vpn` network namespace, hide.me Free,
VPN-routed Codex, and T3 Code on the host network. Normal use is `codex`,
`codex resume`, or opening T3 Code from the Niri launcher. Initial VPN secret
provisioning is required on each machine before these commands can start.

## Architecture

`netns-vpn` creates a persistent namespace and installs an independent IPv4/IPv6
nftables filter before starting networking. `netns-vpn-underlay` provides a TAP
interface with slirp4netns userspace NAT. This needs no host veth, forwarding,
NAT rules or default-route changes. Slirp's host-loopback access and DNS proxy
are disabled. NetworkManager, Tailscale, Docker and browsers stay on the host.

The official hide.me CLI runs entirely inside `vpn`. It negotiates WireGuard
credentials dynamically, so a Free account needs no static WireGuard profile.
The reproducible package pins upstream v0.9.14, source and Go dependency hashes,
and installs its pinned CA resource. It never runs the upstream installer or
fetches executable updates during activation.

The independent output filter allows only loopback, `hm0`, and TCP/UDP on `tap0`
with reserved mark `0x486d`. The CLI marks its API/DoH sockets and WireGuard's
kernel transport socket. Applications have no capabilities and cannot set that
mark. There is no blanket HTTPS, UDP, UID or established-output exception.
The upstream routing kill switch is also enabled (priority 10, table 55555).
On restart, the service removes stale tunnel/routing state left by a crash while
the independent filter remains installed. Loss of the VPN never enables host
fallback. Userspace NAT may limit throughput compared with a host veth.

The client writes a private runtime resolver file, bind-mounted writable over
its `/etc/resolv.conf`. App launches bind the same file read-only in a private
mount namespace. Both use `hosts: files dns` and mask `/run/nscd`, preventing
host NSS/cache IPC from bypassing DNS isolation. Before connection, the resolver
points at namespace loopback. VPN-provided IPv4/IPv6 DNS replaces it on connection.
`NetworkNamespacePath` alone would not provide this filesystem isolation.

## Configuration

The shared NixOS options are:

```nix
my.system.services.networkNamespaces = {
  enable = true;
  namespaces.vpn = {
    enable = true;
    provider = "hide-me"; # currently the only provider
    killSwitch = true;   # required; disabling it fails evaluation
    server = "free-nl";  # default; use a Free endpoint for a Free account
    bootstrapTokenFile = null; # optional runtime secret path, never a Nix path
    egressProbeUrls = [
      "https://api.github.com/"
      "https://www.cloudflare.com/cdn-cgi/trace"
    ]; # external connectivity checks, via VPN only
  };
};
```

Namespace names must start with a letter, contain only letters, digits, `_` or
`-`, and be at most 32 characters. Each name gets separate runtime and persistent
state. The PC and laptop profiles use identical shared modules and separate
machine-local tokens. The existing VPNBook module is preserved.

Home Manager options:

```nix
my.user.ai.codex = {
  enable = true;
  networkNamespace = "vpn"; # null installs ordinary Codex
};
my.user.ai.t3Code.enable = true;
```

`codex.package` is the installed wrapper; `codex.unwrappedPackage` is the original
pinned llm-agents package. Only the wrapper is installed in the user profile.
T3 Code uses the existing unstable input's 0.0.40 package with supported Electron
43; stable's 0.0.24 depends on an unsupported Electron. No input update or global
insecure-package exception is required. T3's bundled Codex PATH dependency is
disabled, and both provider settings locations specify the wrapper's absolute
executable path. Automatic T3 updates are disabled in its desktop executable.
Home Manager merges essential provider settings into mutable preferences; it does
not replace conversations, worktrees, projects, sessions or existing `.codex`.

## Provisioning hide.me authentication

On each machine, after building or installing the package, authenticate in a
private terminal. Before activation, replace `CLIENT_STORE_PATH` with the built
hide.me package path; after activation use `hide.me` directly.

```bash
umask 077
mkdir -p ~/.local/state/hide-me-bootstrap
cd ~/.local/state/hide-me-bootstrap
CLIENT_STORE_PATH/bin/hide.me --tokenFile "$PWD/accessToken.txt" token free-nl
```

Enter credentials only at the prompts. This token-only command does not change
routes or DNS. Check the `Access-Token stored` message and a nonempty private file;
upstream sometimes returns zero even on failure. Never print the token or include
it in source, a Nix path, a process argument or logs. Install it once:

```bash
sudo install -d -o root -g root -m 0700 /var/lib/hide-me-vpn
sudo test ! -e /var/lib/hide-me-vpn/accessToken.txt && \
  sudo install -o root -g root -m 0600 \
    "$HOME/.local/state/hide-me-bootstrap/accessToken.txt" \
    /var/lib/hide-me-vpn/accessToken.txt
```

Do not overwrite an existing refreshed token during rebuilds. After successful
connection, remove the temporary bootstrap copy. The service's mode-0700 state
directory contains its mutable mode-0600 token. The CLI can refresh it in place.
Do not run multiple clients sharing that token file. Each machine authenticates
independently. For deliberate reauthentication, stop `hide-me-vpn`, privately
create a fresh token, install it, and restart the service.

Alternatively, set `bootstrapTokenFile = config.sops.secrets.NAME.path` for an
existing root-readable SOPS secret. The service copies it only when persistent
state has no token; subsequent refreshes never write to the SOPS file. Secret
provisioning and mutable authentication state are separate from reproducible
packages, services and configuration. A fresh installation needs both.

## Services and recovery

| Unit | Responsibility |
| --- | --- |
| `netns-vpn.service` | Persistent namespace, loopback, private DNS/NSS resources, nft filter |
| `netns-vpn-underlay.service` | Restricted slirp TAP underlay; restarts on failure |
| `hide-me-vpn.service` | Root client with only CAP_NET_ADMIN, private DNS mounts and mutable state |
| `netns-vpn-health.timer` | Schedules external HTTPS probes every 30 seconds |
| `netns-vpn-health.service` | Probes from the VPN namespace with isolated DNS; updates `/run/network-namespaces/vpn/ready` on success |

Every launch performs a fresh privileged local check: active client service,
filter present, both route families through `hm0`, a recent WireGuard handshake,
and VPN resolver configured. It additionally requires a successful HTTPS probe
from the preceding 90 seconds. The external probe runs on the timer, not on
every Codex launch. Failed or in-progress probes preserve the last success
until it expires; VPN disconnection still fails the independent local checks.
A stale or missing marker refuses launch with exit 125;
a marker alone cannot bypass local checks. By default GitHub and Cloudflare
receive periodic HTTPS requests; customize destinations using `egressProbeUrls`.
Probe success proves some external connectivity, not that every website or
Codex API is reachable. An outage after a successful probe can still make an
already-launched app stall, but nftables keeps its traffic fail-closed.
The probe unit mounts the same isolated DNS and NSS files as the VPN service.

The client handles short outages through its dead-peer/reconnection logic;
systemd restarts crashes. Namespace and underlay services are retained during
ordinary rebuilds to avoid destroying active sessions. A deliberate namespace
policy/underlay configuration change requires a controlled restart or reboot.
Restart only the VPN client for routine connection recovery:

```bash
sudo systemctl restart hide-me-vpn
systemctl status netns-vpn netns-vpn-underlay hide-me-vpn
sudo journalctl -u hide-me-vpn -b --no-pager -n 80
sudo /etc/network-namespaces/vpn-check
sudo systemctl status netns-vpn-health.service
sudo journalctl -u netns-vpn-health.service -b --no-pager -n 30
sudo ip -n vpn route show table all
sudo ip -n vpn -6 route show table all
sudo ip netns exec vpn nft list table inet agent_workspace
sudo ip netns exec vpn wg show hm0 latest-handshakes
```

Avoid dumping WireGuard configuration or token files. For full teardown, stop the
client, underlay, health timer and namespace in that order. Processes retaining
an old namespace keep its filter until they exit. Restarting `netns-vpn` destroys
the named namespace and disconnects existing agent sessions.

## Launcher and Codex

The generic launcher uses a sealed descriptor to preserve the caller's environment
through a command-specific sudo rule. The privileged helper accepts only immutable
application registrations for their authorized normal user. It checks readiness,
enters the network namespace, isolates DNS mounts, restores supplementary groups,
drops all root identities and capabilities, enables `no_new_privs`, closes extra
descriptors, then executes the fixed application. User environment is interpreted
only after privilege drop. No arbitrary root shell or `ip netns exec` is authorized.
The sudo entry does not allocate a pseudo-terminal; stdio, cwd, arguments and exit
status are preserved. Its monitor forwards normal terminal signals.

All local children, including `codex app-server` command children, inherit the
namespace. Existing `.codex`, alternate `CODEX_HOME`, SSH-agent socket, Git and
normal project permissions remain available. Codex approval/sandbox settings are
not changed. `no_new_privs` prevents setuid/sudo elevation from agent children;
this is required to prevent changing the reserved mark or escaping the namespace.
Host UNIX services such as Docker, forwarded SSH endpoints or other host daemons
can perform work outside this namespace; network isolation applies to local
process sockets, not work delegated to those services. Existing host integration
is not an independent security sandbox against the authorized machine owner.

An existing Codex login can be reused. For a new login, use
`codex login --device-auth`: the host browser cannot reach a callback on the VPN
namespace's loopback. Device authorization must be enabled for the account.
See [official Codex authentication guidance](https://learn.chatgpt.com/docs/auth).
Do not change sandbox/approval configuration to work around login or networking.

To register another package, add a fixed system registration and install a wrapper:

```nix
my.system.services.networkNamespaces.applications.mytool = {
  namespace = "vpn";
  user = "evgen2571";
  package = pkgs.mytool; # lib.getExe fixes the executable at build time
};
# A writeShellScriptBin wrapper can exec:
# ${lib.getExe config.my.system.services.networkNamespaces.launcherPackage} mytool "$@"
```

The application registration chooses the executable, not its arguments. Do not
register a generic shell unless you intend to authorize that user's arbitrary
unprivileged commands inside the namespace. Codex registrations are automatic.

## Remote builds and temporary activation

Use WSL only for editing/Git/SSH. Run all Nix commands on native NixOS, in the
separate `~/dev/my-nixos-vpn-test` checkout. Include new files in its Git index.
Build sequentially:

```bash
nixos-rebuild build --flake .#nixos-lp
readlink -f result # record the laptop output before the next build replaces result
nixos-rebuild build --flake .#nixos-pc
```

Never activate the PC configuration on the laptop. Before laptop activation,
record `/run/current-system`, routes, resolver checksum and the SSH/Tailscale
route. Obtain approval for the first live activation. Schedule a root systemd
rollback timer to run the recorded old generation's `switch-to-configuration test`
independently of SSH, then activate the built laptop generation with `test`.
Do not restart NetworkManager, Tailscale or SSH separately. Temporary activation
does not update the boot generation; reboot is an additional recovery route.
The reviewed helper `tests/network-namespaces/activate-laptop.sh` records this
state, provisions the token only if absent, arms a 20-minute rollback and performs
temporary activation. It refuses non-laptop outputs and immediately rolls back
if activation fails or the host default routes/resolver change. Run it locally
only after approval, with the recorded laptop system path, private bootstrap path
and the actual SSH peer IP as its three arguments. It does not cancel rollback.
Keep rollback armed until host connectivity, VPN and wrapper checks have passed;
only then cancel its timer. Home Manager preferences and refreshed tokens are
mutable state and are not reverted by switching generations.

## Verification checkpoint

Native laptop kernel 7.2.6: the official package builds and lists Free servers.
A live disposable namespace connected to hide.me Free, with different host/VPN
IPv4 egress and working VPN IPv6 and DNS. Capability-free app probes stayed
blocked with no VPN, missing/invalid token, unreachable server, failed DNS,
clean client stop, removed WireGuard tunnel and killed client. Reconnection after
clean stop and a simulated underlay outage succeeded once underlay routes were
reapplied. Host routes/resolver were unchanged. Actual host suspend/resume is a
separate production check.
Six launcher tests verified identity/groups, arguments, environment, cwd, stdio,
exit status, signal handling, file access, child namespace inheritance, complete
capability drop and refusal of missing/unready/unsafe targets. These used a test
sudo adapter; production sudo/systemd integration still requires activation.
Real generated service scripts passed repeated initialization/cleanup and stale
crash-state recovery in subordinate user namespaces. Focused module evaluation
checks no added host NAT/firewall rules and the dependency/privilege configuration.

Full host builds are in progress. Production activation, suspend/reconnect,
wrapped Codex authentication/exec/resume/app-server and graphical T3 provider
acceptance remain pending. PC runtime verification requires the PC itself.
After activation, open T3 normally in Niri, select Codex, create a session in an
existing project, run a command reporting `id`, `/proc/self/ns/net` and VPN egress,
then close/reopen and resume it. Compare with the host namespace/egress and verify
that the project and conversation persist. Do not report this manual test as
passed until it has actually run.

Pinned implementation references: [hide.me README](https://github.com/eventure/hide.client.linux/blob/v0.9.14/README.md),
[marked API sockets](https://github.com/eventure/hide.client.linux/blob/v0.9.14/rest/client.go),
[WireGuard implementation](https://github.com/eventure/hide.client.linux/tree/v0.9.14/wireguard),
[T3 0.0.40 source](https://github.com/pingdotgg/t3code/tree/v0.0.40).
