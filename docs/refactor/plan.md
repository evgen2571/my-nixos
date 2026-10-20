# Module inventory and equivalence plan

Spec: [#50](https://github.com/evgen2571/my-nixos/issues/50), under #49.
Baseline: `cb75bb68aaf0412f26488d63e4556e36c31193bd`.
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
