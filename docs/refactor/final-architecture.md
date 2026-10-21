# Final feature-first architecture (#55)

Spec: [#55](https://github.com/evgen2571/my-nixos/issues/55), final stage of
[#49](https://github.com/evgen2571/my-nixos/issues/49). Stage starts at `9084987`.
The functional baseline stays `cb75bb68aaf0412f26488d63e4556e36c31193bd`.
The single integration PR is [draft #57](https://github.com/evgen2571/my-nixos/pull/57).

## Final layout and discovery

All 75 optional entries, six explicit entries and 230 mapped module/support
assets in [the original inventory](inventory.json) are accounted for. The module
tree contains exactly its approved targets, including disabled optional features,
private helpers, packaging assets, patches and scripts. Fish and Kitty are the
only consolidations; Niri/Fish scope pairs are colocated. Program-native sources
remain under `config/`. The [approved tree](target-tree.md) and historical
[migration ledger](migrations.json) remain available for review.

The catalog discovers only typed entries under `ai`, `apps`, `desktop`, `dev`,
`files`, `services`, `hardware` and `server`. It has no dependency on the old layout,
inventory or ledger. Old category roots, untyped scanning, `default.nix` fallback,
compatibility registrations and the injected `legacyEntries` argument are removed.
Helpers and symlinks are not discovered. Core baselines, primary-user wiring,
secrets and deployment remain explicit assembly outside the feature roots.

`lib/module-order.json` contains only current typed paths, preserving the existing
75 entries' order. Catalog root rules alone determine scope and profile eligibility.
New ordinary features follow in root/recursive-name order without registration;
see [module conventions](../reference/modules.md). The final equivalence check maps
all original entries unconditionally, without a partial-migration fallback.
Directory fixtures cover final discovery rather than the removed compatibility API.
The comparison utility retains `--migrations` solely to reproduce historical stage
evidence; neither production discovery nor the final check uses it.

Desktop system/home inventories remain 23/47, server inventories 12/23.
Unconditional personalized SSH, desktop-only system Fish, shared home Fish,
optional server-base and explicit server baseline keep their original distinctions.
No option interface, feature selection, package selection, deployment mapping,
activation/state boundary, service, privilege, namespace/recovery rule or production
guard changes in this stage. No live activation or runtime migration is performed.

## References and private coordination

Current assembly, host/user setup, templates, checks, scripts, README and operations
references use final paths. Two remaining stale documentation references were
corrected: terminal tools and server service selection. Old paths remain only in
intentional historical contracts/handoffs and negative/comparison fixtures.
The original baseline snapshots, hashes and ordered catalogs remain unchanged.

The available private input at `70c2c843dba1ee03812bbf42ae5f85f89162d0a8`
was reconfirmed PRIVATE. It is unchanged and has no direct old public-module
imports; no separate private commit is required. This audit covers that revision,
not unavailable consumers. No private values, credentials or snapshots are published.
The public repository remains the only build/deployment root.

## Verification and remaining work

[The final verification record](verification.md#final-typed-only-architecture-55)
records exact commands/results, strict baseline comparisons, clean committed-source
validation and private/manual limits. Normalization remains confined to exact
repository roots and the two previously reviewed primary-user module references;
no arbitrary store hashes, commands or privileges are removed.

No behavior changes are deferred from this stage. Making personalized SSH an
optional generic-user feature, changing package pins, redesigning options or
installers remain separate work. Existing Neovim smoke/competitive limitations,
physical boot/login, desktop appearance, production decryption and real VPN egress
remain outside what public evaluation and disposable fixtures can establish.
The PR stays draft for the maintainer; parent #49 is not closed or merged.
