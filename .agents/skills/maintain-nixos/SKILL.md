---
name: maintain-nixos
description: Troubleshoot NixOS build, configuration, activation, or service failures; change deployment, VPN/network namespaces, boot, storage, networking, authentication, or secrets. Excludes routine app edits, documentation wording, and simple module additions.
---

# Maintain my-nixos

Inspect the affected host profile, owning sources, and direct callers. For a
failure, read the error and relevant logs before changing the configuration.

Read only the documentation needed for the task:

- VPN/network namespaces: [VPN notes](../../../modules/services/network-namespaces/README.md)
  and the implementation. Preserve fail-closed routing, DNS isolation, scoped
  privileges, and recovery.
- Secrets/private inputs: [secrets](../../../docs/secrets.md). Before copying
  personal material, verify the destination repository is private; commit and
  review private-repository changes separately.
- Deployment, activation, or recovery: [maintenance](../../../docs/maintenance.md)
  and the affected deployment code.

For boot, storage, networking, or authentication changes, establish a recovery
path and identify writable data that needs backing up before live work.

Use the existing `just` recipes for evaluation and affected-host builds. Production
hosts require their matching private input. Check the failure that motivated the
change and retain NixOS assertions and upstream package checks.
