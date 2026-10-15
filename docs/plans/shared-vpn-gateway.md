# Shared VPN gateway execution plan

- [x] Read architecture and namespace implementation; clean isolated feature worktree.
- [x] Inspect PC session and tailnet: this session is inside active `vpn`; PC provider active, laptop offline, server Tailscale IP `100.96.206.10`.
- [ ] Audit server live state: blocked because this session cannot reach host Tailscale, and `no_new_privs` forbids sudo. Host-side read-only commands are in `docs/shared-vpn-gateway.md`.
- [x] Evaluate Tailscale-only routing/proxies; select a host-born WireGuard link over existing Tailscale to avoid host forwarding/default-route changes and extra daemon identities.
- [x] Reuse namespace isolation; server keeps slirp/Hide.me, clients have no provider service. Normal Orca retains host SSH; `orca-vpn` is explicit.
- [x] Configure three profiles, runtime-key paths, automated checks, migration/rollback documentation and a non-activating rollback preparation helper.
- [x] Build all three outputs and run `nix flake check`, ShellCheck and disposable kernel integration tests. Mock tests cover simultaneous clients, IPv4/IPv6, DNS, VPN/transport loss, recovery and unchanged test-host routes/resolver.
- [ ] Approved staged activation with independent rollback, key/token provisioning and real simultaneous-client/leak/host-network acceptance.

No activation is authorized or performed. Existing PC VPN and desktop provider/token implementation are preserved. No credentials or keys were provisioned. Actual Hide.me/Tailscale egress, DNS packet captures, production sudo/Orca/Codex integration, server Docker/networking, and suspend/resume remain unverified. Public-key exchange, server token provisioning if absent, an online laptop and a host-side authorized execution session are prerequisites.

The requirement to keep the current provider connected until the new live provider is verified conflicts with the one-connection limit. Offline transport/filter verification is complete; a live check requires explicit approval for an exclusive handover with a short outage. The documented client rollback leaves local providers masked until the server is confirmed stopped.
