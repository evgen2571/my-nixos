# Shared VPN gateway execution plan

- [x] Keep existing server namespace/slirp/Hide.me architecture and Tailscale transport.
- [x] Apply server-only requirement: no desktop provider, underlay, token declaration or fallback; permanent masks survive old-generation boot.
- [x] Replace runtime key generation/exchange with host-specific SOPS private keys and declarative public peers. Server SOPS authentication entry is empty pending private provisioning.
- [x] Simplify rollback: desktop restores host access with local networking services disabled, never a provider recovery path. Shared namespace changes activate automatically.
- [x] Native and real-SOPS VM tests pass: automatic client activation/boot/reboot, lifecycle and old-generation masks; all three hosts build.
- [x] Final production-profile assertions, flake/format/shell checks pass; native and real-SOPS VM regressions pass.
- [x] Commit implementation and update existing draft PR #12 only; live acceptance remains pending.
- [ ] Operator privately provisions server SOPS token, obtains approval, disables both desktops first, arms rollback, activates gateway/clients and runs live acceptance.

No live networking activation is authorized. Private WireGuard keys were generated only in memory and encrypted to each host/admin recipient; plaintext never entered Git or the Nix store. No live host credentials, masks, timers, providers or routes changed. The prior host audit confirmed server Tailscale `192.0.2.11`, successful host SSH and healthy Docker. Real Hide.me and application acceptance remain pending.
