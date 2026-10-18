# Agent instructions

This repository runs my PC, laptop, and server. Treat configuration changes as
operational work and preserve existing user changes.

## Start here

1. Inspect the working tree and use the [task-routing skill](.agents/skills/task-routing/SKILL.md)
   to find the owning module, source dotfiles, host profile, and relevant checks.
2. Read the source before changing behavior. State whether the change affects
   declarative configuration, generated files, or mutable runtime state.
3. Keep changes focused. Reuse nearby patterns and avoid unrelated dependency,
   formatting, or architecture changes.

Load only relevant [agent guidance](.agents/skills/README.md). Human explanations
live in the [documentation index](docs/index.md), with authoritative
[architecture](docs/concepts/architecture.md), [module conventions](docs/development/modules.md),
and [source selection](docs/reference/secrets.md#source-selection).

## Preserve these boundaries

- Host profiles select features; reusable NixOS/Home Manager modules implement
  them. Pass host-specific user settings through `my.primaryUser.home.settings`.
- Discovery imports individual `.nix` files recursively, except directories with
  `default.nix`, which are one module. Do not manually import discovered modules
  or accidentally expose implementation helpers to discovery.
- Preserve existing `my.*` option organization and `lib/config-paths.nix` adapters.
  Inspect mutable boundaries before changing activation: Neovim copies preserve
  generated Matugen files; browser sessions and agent resources remain writable.
- `my-nixos` is the sole build/deployment root. For source, installation, or
  deployment work read [installation](docs/getting-started/installation.md),
  [source selection](docs/reference/secrets.md), and [deployment guards](docs/guides/deployment.md#deployment-guards).
  Never bypass existing-host private-input guards or commit personal input overrides.

## Live state and sensitive data

- Never install, activate (`switch`, `boot`, or `test`), roll back a live host,
  restart VPN/networking/SSH/display services, or change firewall routes without
  explicit authorization. Non-activating evaluations/builds are allowed.
- Before VPN work read the [gateway runbook](docs/guides/shared-vpn-gateway.md)
  and [namespace reference](docs/reference/network-namespaces.md). Preserve
  fail-closed IPv4/IPv6/DNS isolation, provider separation, and recovery guards.
- Never inspect, print, commit, or interpolate private keys, tokens, credentials,
  or decrypted secrets into logs or Nix store expressions. Commit only encrypted
  secret documents and public key/certificate material; follow [SOPS](docs/reference/secrets.md).
- For server storage, backup, authentication, or boot work read
  [server operations](docs/guides/server.md) and the Nix definitions. Sibling
  `/srv/*` paths are not implicitly on `/srv/storage`.
- Never delete profiles, caches, databases, secrets, or legacy runtime state just
  because a module no longer references them. Preserve independent recovery access.

## Verify and deliver

- Documentation: verify links, anchors, and paths; run `git diff --check`.
- Nix: check formatting and evaluate/build affected hosts without activation.
  Shared modules need coverage of every affected host. Review `nix fmt` output
  for unrelated changes. `nix flake check --no-build` evaluates checks; it does not
  execute them.
- Neovim: inspect `tests/neovim/run.sh` and run relevant smoke checks when available.
  VPN: use `tests/network-namespaces/` and keep live acceptance separately authorized.
- Stay on a feature branch; use scoped, lowercase `type: short description`
  commits. Open a PR to `main`; never merge without approval.
- Report changed files, preserved behavior, actual checks, unverified work, and
  required deployment/manual follow-up. Historical evidence is not a fresh test.
