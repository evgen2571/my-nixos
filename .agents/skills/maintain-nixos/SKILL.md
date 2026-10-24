---
name: maintain-nixos
description: Change or troubleshoot NixOS hosts, modules, application configs, docs, or checks in this repository.
---

# Maintain my-nixos

Read the affected host profile and owning source before editing. Start with [hosts](../../../hosts/README.md), [modules](../../../modules/README.md), or the closest `config/*/README.md`. For VPN changes, read [its note](../../../modules/services/network-namespaces/README.md) and the implementation, not just the summary. For credentials or activation, read [secrets](../../../docs/secrets.md) and [maintenance](../../../docs/maintenance.md).

Keep host selections in `hosts/`, reusable modules in `modules/`, and app-specific files in `config/`. Follow typed NixOS/Home Manager discovery. Preserve generated/writable state, private-input guards, fail-closed VPN routing, and existing feature behavior.

Use flake evaluation and affected-host builds without live activation. This repository keeps no test suite or generated verification artifacts; preserve NixOS assertions, deployment guards, and upstream package checks. Production builds need the original private input, and evaluation cannot replace runtime verification. Review changed links and document only what a reader needs; leave implementation evidence in Git/issues. Report the checks that actually ran and what wasn't verified.

Never switch or restart a running host, rewrite history, change remote visibility, or handle secrets without explicit approval.
