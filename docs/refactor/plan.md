# Module inventory and equivalence plan

Spec: [#50](https://github.com/evgen2571/my-nixos/issues/50), under #49.
Baseline: `pre-cleanup-history`.
Integration branch: `refactor/feature-first-modules`.

- [x] Capture original ordered catalog outputs, explicit assembly and every module/helper/asset; assign typed targets without moving source.
- [x] Capture public assembled host/Home Manager option schemas and effective behavior; provide strict reproducible comparisons with narrow source-root normalization.
- [x] Run baseline flake/application/VPN/VM checks, audit private access without publishing material, and record limitations.
- [x] Review standards and spec, verify the clean committed tree, publish one draft integration PR and update issue checkboxes.

The agreed seams are the four catalog outputs and three assembled hosts/users
(parent issue Testing Decisions). Fixtures must include disabled options. Keep
package paths, command arguments, file destinations/permissions and activation
ordering. Never normalize arbitrary store hashes. A changed derivation requires
content/build review before accepting a relocation. Private snapshots stay local.
No module migration, input update or live activation is part of this stage.

## Typed discovery (#51)

Approved spec: [#51](https://github.com/evgen2571/my-nixos/issues/51).
Implementation remains on the current integration branch; no PR creation,
ready-for-review transition, merge or activation.

- [x] Add directory-fixture tests at the catalog seam, first demonstrating typed
  entries and ignored helpers fail with the old discovery.
- [x] Add typed discovery alongside narrowly scoped legacy discovery. Freeze a
  central compatibility table from the approved inventory to preserve existing
  ordering, scope and eligibility. Validate missing/duplicate/wrong-scope entries.
- [x] Extend fixtures for recursive directory siblings, mixed migrations, Fish's
  per-entry exception, explicit infrastructure exclusions and diagnostics.
- [x] Document rules, extension example and serialized compatibility ownership;
  final #55 must remove legacy discovery/table after all migrations.
- [x] Run focused fixtures, formatting/dead-code checks, full flake checks and
  public assembled-host comparison. Review standards/spec and commit changes.

## Ordinary features and baselines (#52)

Approved spec: [#52](https://github.com/evgen2571/my-nixos/issues/52).
Continue inline on `refactor/feature-first-modules`; retain draft PR #57.
The agreed catalog and three assembled-host seams remain authoritative.

- [x] Record the 68 assigned discovered entries and four explicit baselines in
  `migrations.json`, referencing the original inventory without changing it.
  Exclude Niri system/home, Noctalia shell/greeter, Neovim, tmux, namespaces,
  secrets and deployment for #53/#54.
- [x] Extend the existing catalog-equivalence assertion/comparator for explicit
  partial migrations; verify mixed ordering and rejection at the agreed seam.
- [x] Move assigned inventory assets, consolidate only Fish/Kitty, repair relative
  paths and baseline callers/templates, and update current documentation links.
  Keep frozen discovery/catalog/compatibility rules untouched.
- [x] Compare inventories, source bytes/modes and public assembled hosts against
  #50; investigate any differences, including the relocated primary-user module
  path. Run focused and full checks plus available private non-activating builds.
- [x] Record exact mapping, boundaries and verification in a stage handoff;
  review Standards/Spec, commit, update issue checkboxes, and retain draft status.

## Complex desktop and development features (#53)

Spec: [#53](https://github.com/evgen2571/my-nixos/issues/53). Stage starts at
`pre-cleanup-history`; keep the current integration branch and draft PR #57. Reuse the
agreed ordered-catalog and three assembled-host seams.

- [x] Extend the ledger with six assigned entries; demonstrate the existing
  catalog-equivalence assertion fails before moving implementations.
- [x] Move all nine mapped files byte-for-byte, retaining private helpers and
  native config sources; update active references without editing shared catalog rules.
- [x] Compare the original inventory, public hosts, deployed content and activation;
  run targeted application checks, complete flake checks and practical artifact builds.
- [x] Record stage evidence/limitations, review Standards/Spec, commit and push
  to the existing draft PR; update issue body and Agent Brief checkboxes.

## VPN, secrets and deployment infrastructure (#54)

Spec: [#54](https://github.com/evgen2571/my-nixos/issues/54). Stage starts at
`pre-cleanup-history`; use the current integration branch and retain draft PR #57.

- [x] Extend the ledger at the agreed catalog seam and demonstrate failure before moves.
- [x] Move all mapped infrastructure entries/assets, repairing explicit assembly,
  test imports, sandbox copies, scripts and current documentation references.
  Preserve frozen discovery/compatibility rules for final #55.
- [x] Compare original inventories, public assembled hosts and meaningful generated
  artifacts; audit private consumers and run available non-activating builds.
- [x] Run focused namespace/recovery/source/deployment checks, disposable isolation
  harness, VM checks, full flake checks, formatting/dead-code and reference checks.
- [x] Record evidence and limits, review Standards/Spec against the stage start,
  commit/push to the draft PR and update issue body/Agent Brief checkboxes.

## Final typed-only architecture (#55)

Spec: [#55](https://github.com/evgen2571/my-nixos/issues/55). Stage starts at
`pre-cleanup-history`; use the current branch and update the existing draft PR #57.
The approved architecture and catalog/assembled-host test seams remain in force.

- [x] Replace transition fixtures with final-contract coverage; demonstrate old-root
  typed entries are rejected/excluded before removing legacy discovery.
- [x] Remove old roots, default fallback, compatibility registrations and injection
  callers. Preserve existing order with a typed-path-only order list; new features
  retain automatic discovery. Keep root scope/profile rules explicit.
- [x] Audit all 230 mapped assets and six explicit entries, references, available
  private consumers and unchanged package/plugin locks; update practical docs.
- [x] Compare final public hosts and ordered catalogs against the exact #50
  baseline. Run focused tests, full flake checks, available VM/isolation and
  non-activating builds; record baseline failures and private/manual limits.
- [x] Review Standards/Spec, commit, validate the clean committed archive, update
  PR #57 with the full migration evidence and issue checkboxes; keep draft,
  do not merge or close the parent.
