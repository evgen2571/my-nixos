---
name: maintain-nixos
description: Change or troubleshoot this repository's NixOS hosts, application configuration, documentation, or checks. Use for repository maintenance; GitHub issue triage has a separate skill.
---

# Maintain my-nixos

Identify the host and subsystem. State whether the change affects declarative
source, generated files, or mutable runtime state. Read the matching row in
[the configuration map](../../../docs/reference/configuration.md), then inspect
the owning module, source configuration, affected profiles, and direct callers.
Load only relevant guides.

- For module discovery, options, or file deployment, read
  [modules](../../../docs/reference/modules.md).
- For ownership or host assembly, read
  [architecture](../../../docs/reference/architecture.md).
- For app behavior, follow the app link in the configuration map. Keep shortcuts
  and plugin ownership unambiguous; preserve generated themes and writable state.
- For VPN changes, read both [VPN operations](../../../docs/operations/vpn.md)
  and [namespace implementation](../../../docs/operations/network-namespaces.md).
  Identify affected roles and what must remain blocked on failure before editing.
- For source selection or private inputs, read
  [secrets](../../../docs/operations/secrets.md) and
  [deployment](../../../docs/operations/deployment.md). Keep paired revisions and
  deployment guards intact.
- For storage or server lifecycle, read
  [server operations](../../../docs/operations/server.md).

Use the nearest existing implementation and keep the diff narrow. Follow the
configuration map's verification table. Inspect test entry points before running
them; Neovim tests require disposable XDG roots and installed plugins, and desktop
validation requires complete generated includes. Builds cannot establish UI
appearance or live VPN egress.

Write documentation for the maintainer's current tasks. Put everyday usage first,
configuration and troubleshooting deeper. Keep commands and safety conditions
precise. Remove obsolete explanations instead of appending migration history.

Before completion, check incoming links after file moves, review the whole diff,
and report what changed, actual checks, remaining risks, and commit/PR references.
Live activation remains separately authorized under root AGENTS.md.
