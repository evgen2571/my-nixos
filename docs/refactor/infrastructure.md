# VPN, secrets and deployment infrastructure (#54)

Spec: [#54](https://github.com/evgen2571/my-nixos/issues/54). Stage starts at
`pre-cleanup-history`; the functional baseline remains
`pre-cleanup-history`. Continue on
`refactor/feature-first-modules`, retaining draft PR #57.

## Mapping and assembly

The cumulative [migration ledger](migrations.json) now covers all 75 discovered
entries and all six explicitly assembled entries. The frozen [inventory](inventory.json)
records exact original bytes, executable modes, scope and profile eligibility.

| Original entry / supporting asset | Approved target |
| --- | --- |
| `modules/system-services/network-namespaces/default.nix` | `modules/services/network-namespaces/nixos.nix` |
| Namespace `namespace.nix`, `shared.nix`, `launcher.nix`, `doctor.nix`, `doctor.py` | Same filenames under `modules/services/network-namespaces/` |
| Namespace `migration/desktop-provider-guard.sh`, `migration/prepare-rollback.sh`, `migration/rollback.sh` | Same filenames under `modules/services/network-namespaces/migration/` |
| `modules/secrets.nix` | `modules/core/secrets.nixos.nix` |
| `modules/deployment/default.nix` | `modules/deployment/nixos.nix` |
| Deployment `preflight.sh`, `install-preflight.patch`, `rebuild-preflight.patch`, `rebuild-tests.patch` | Unchanged, under `modules/deployment/` |

All nine namespace files and the deployment entry move byte-for-byte. Secrets
changes only its two relative references to `lib/check-sops-source.py` and
`.sops.yaml`, preserving their resolved sources. Namespace package calls retain
their relative depth and original package implementations. Native configuration,
package pins and host profiles remain unchanged.

`flake/hosts.nix` explicitly imports secrets and deployment at their original
positions, before catalog entries, extra modules and selected private modules.
Both infrastructure roots stay outside optional discovery. The namespace entry
retains its original ordered catalog slot and desktop/server eligibility; its
helpers are private explicit imports, never discovered modules. No shared catalog,
discovery or compatibility registration was edited. Legacy support and the frozen
compatibility table remain for #55 to remove in a coordinated final stage.

Tests now import the explicit namespace `nixos.nix`. Recovery CLI fixtures,
sandbox copies, shellcheck paths, VM migration bundles and the rollback preparation
wrapper use the new helper locations. Current operations/reference links are
updated; original paths remain intentionally in frozen evidence, the migration
ledger, compatibility registrations, historical handoffs and the legacy-exclusion
fixture. No runtime migration/recovery command was run on a real host.

## Preserved boundaries

Roles, namespace names, transport addresses/routes, independent filters, DNS/NSS
isolation, scoped sudo/capabilities, executable registration, startup dependencies,
lifecycle records and bounded recovery remain unchanged. Codex/Orca registrations
still select their original unwrapped executable packages. No transport, routing
or primary-user architecture is redesigned.

Source modes and selected runtime secret paths, SOPS consumers/ownership/modes,
account overrides and optional private imports are unchanged. Deployment keeps
production build refusal, patched install/rebuild preflight and activation guards.
No bootstrap, identity, token, hold, cache, database or other mutable state is
removed or rewritten. Existing [VPN recovery](../operations/vpn.md),
[namespace rollback](../operations/network-namespaces.md) and
[deployment recovery](../operations/deployment.md#rollback-and-recovery) remain
authoritative; activation still requires separate authorization.

## Verification and private consumers

Use the original [comparison contract](README.md):

```sh
python3 tests/module-equivalence/compare.py capture "$PWD" /tmp/issue54-evidence
python3 tests/module-equivalence/compare.py compare \
  /tmp/issue50-evidence-baseline /tmp/issue54-evidence \
  --mapping docs/refactor/inventory.json --migrations docs/refactor/migrations.json
```

The available private input at audited revision
`70c2c843dba1ee03812bbf42ae5f85f89162d0a8` was reconfirmed PRIVATE. Its eight Nix
files contain no direct public-module imports requiring coordinated path changes;
no private checkout changes are necessary. This audit covers that revision only,
not unavailable external consumers. Private data stays local, and public evidence
export guards remain intact.

Exact checks, private infrastructure comparison/build results and remaining
manual limits are recorded in [verification.md](verification.md#vpn-secrets-and-deployment-infrastructure-54).
