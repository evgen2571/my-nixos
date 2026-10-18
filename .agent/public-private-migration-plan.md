# M02 execution plan

Spec: docs/public-private-migration.md and issue #29. Implement inline on a
feature branch; preserve real host assembly, discovery, HM and runtime boundaries.
Only declarative source, encrypted documents and narrow metadata move. No activation.

- [x] Capture all three current host semantic evaluations and derivation paths.
- [x] Add explicit none/local/private selection and the empty nested private input.
  Test selection exclusivity, missing paths and incomplete interfaces at the selector seam.
- [x] Guard consumers and existing-host deployments. Preserve credentialed SOPS
  metadata, user policy and VPN containment. Test deployment refusal without activation.
- [x] Populate the verified-private sibling with ciphertext and reviewed narrow
  overrides on its own branch; remove only corresponding public HEAD material.
- [x] Add safe host/private templates and guides; forward deployment helper flags.
- [x] Evaluate all three modes and template host; compare credentialed semantics.
  Run focused/full registered checks and non-activating host builds where supported.
- [x] Review standards and spec independently; correct both findings and commit fixes.
- [ ] Open separate public/private PRs after final checks.

Watch: direct rebuild profile mutation precedes upstream pre-switch checks;
missing identity and source material must not silently deploy. No secret reading,
plaintext credentials in fixtures, private source in public lock, or history rewrite.
