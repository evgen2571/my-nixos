# Agent instructions

This repository configures three real NixOS hosts. Keep changes scoped and
preserve existing user work.

## Route the task

For configuration, documentation, debugging, or validation work, read
[maintain-nixos](.agents/skills/maintain-nixos/SKILL.md). For GitHub issues or
triage, read [nixos-tracker](.agents/skills/nixos-tracker/SKILL.md).
Open these files directly when the client does not discover local skills.
Skills link to the same documentation humans use; there is no separate agent
reference tree.

## Required boundaries

- Work on a feature branch. Inspect the owning module, sources, affected host
  profiles, and direct callers before editing. Preserve behavior outside scope.
- Keep feature choices in host profiles and reusable behavior in modules.
  Follow the existing `my.*` option structure and module discovery; do not
  manually import already-discovered modules.
- Preserve writable/generated state. Never delete profiles, caches, databases,
  secrets, or legacy runtime files because source no longer references them.
- Never inspect or print private keys, credentials, bootstrap tokens, or decrypted
  secrets. Commit only encrypted secret documents and public keys/certificates.
  Private Git inputs also enter the Nix store.
- Keep this repository the sole build/deployment root. Preserve production
  private-material guards and keep personal overrides out of the public lock.
  Verify PRIVATE visibility before copying sensitive material; commit and review
  private-repository changes separately.
- Live activation needs explicit authorization: no `switch`, `boot`, service
  restart, route/firewall change, display-manager restart, or runtime migration
  without it. Ordinary non-activating evaluation and builds are allowed.
- VPN changes must preserve fail-closed isolation, DNS, scoped privileges, and
  recovery. Storage, boot, authentication, and access changes need a recovery path.

## Delivery

Run checks appropriate to the change. Do not weaken them to obtain a pass.
Review formatter output for unrelated changes. Report actual results and remaining
manual checks; evaluation is not a build or runtime test.

Commit focused changes with `type: lowercase description`; open a PR unless the
user requests otherwise. Do not merge into main without explicit approval.
