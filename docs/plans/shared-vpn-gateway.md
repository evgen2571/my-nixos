# Shared VPN gateway execution plan

- [x] Read architecture and namespace implementation; preserve standalone provider and existing PC connection.
- [x] Evaluate Tailscale-only designs; retain a host-born WireGuard link over existing Tailscale, with namespace-only forwarding/NAT.
- [x] Configure three profiles, opt-in Orca wrapper, runtime keys, migration/rollback documentation and original disposable integration checks.
- [x] Inspect server through a separate Orca host terminal: plain SSH succeeds; server confirms `100.96.206.10`, active SSH/Tailscale, ordinary host routing, healthy Docker, no provider/namespace, nightly suspend enabled. Server sudo requires a password; token state unknown.
- [x] Review PR #12 for reboot/rollback/lifecycle safety: replace ephemeral masks with persistent system.control masks, tear down retained namespace resources during rollback, pin independent timer PATH, propagate namespace/DNS restarts.
- [x] Run updated systemd VM test: startup/missing-peer retry, DNS changes/failure, transport recovery, retained-app rollback and old-generation reboot guard.
- [x] Rebuild three hosts; updated systemd VM, disposable IPv4/IPv6, formatting and shell checks pass.
- [x] Complete final flake check; the reviewed commit targets existing PR #12 only.
- [ ] Operator provisions public peer keys and server token if absent; guarded approved exclusive cutover and live acceptance.

No networking activation is authorized. No live masks/timers/providers/routes/namespaces were changed. The existing PC provider remains active. Both desktops must be online and persistently guarded before the server provider can start; an offline unguarded laptop blocks cutover. Guards survive old-generation boot and are removed only after the server provider is confirmed stopped. Exact host-side steps are in `docs/shared-vpn-gateway.md`.
