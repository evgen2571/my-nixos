# M03 validation and operator handoff

Issue #30. Documentation and validation only unless a check identifies a defect.
No installation, activation, identity changes, service restarts or visibility changes.

- [x] Inspect post-M02.5 source selection, templates, guards and historical evidence.
- [x] Complete standard public-only installation and one-repository SOPS instructions.
- [x] Document paired private revisions, per-host deployment/recovery and normal edits.
- [x] Fresh public-only and pinned-private checks/builds; standalone none/local VM test.
- [x] Compare protected three-host semantics with recorded M02.5 outcomes; record limits.
- [x] Review standards/spec, verify documentation, commit on the assigned branch.

Test boundaries are the issue's complete-host evaluation/build, disposable template
first-login, source-policy and deployment-preflight interfaces. Reuse their tests.

Final review: Standards found no blocking violations; Spec found no remaining
actionable findings after fresh pre-split/pre-extraction supplemental comparisons.
Evidence and limitations: [M03 validation](../docs/archive/m03-validation.md).

## PR #41 documentation revision

Follow the latest README project direction on main (`47707c8`): existing personal
hosts first, independent reuse second. Keep this within #30; no runtime changes or
#31-wide reorganization. Preserve the recorded M03 evidence separately from checks
performed for this documentation revision.

- [x] Shorten installation to audience routing plus the secretless adaptation path.
- [x] Keep source/SOPS details and maintainer operations in their focused references;
  remove the duplicate installation procedure from the host template.
- [x] Verify changed links/examples/references and review both reader paths.
- [x] Update the existing PR without adding a commit (operator authorized the
  amendment and branch-only force-with-lease update).
