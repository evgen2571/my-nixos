# Agent instructions

This repository configures three real NixOS hosts. Treat changes as operational code, not disposable dotfiles. Follow these rules for work in this repository; use the closest existing implementation as the primary style reference.

## Start small

1. Identify the requested host(s) and subsystem. Use [docs/task-routing.md](docs/task-routing.md) to locate the first files; do **not** read the whole repository for a local change.
2. Inspect the owning module, the corresponding `config/` source (if any), relevant host profile(s), and only the subsystem documentation needed for this task.
3. State whether the edit changes declarative configuration, generated files, or mutable runtime state. Preserve existing behavior outside the requested scope.
4. Reuse the nearest pattern and keep the diff narrow. Do not mix documentation migrations, dependency updates, cleanup, and feature work without a reason.

For architecture, read [ARCHITECTURE.md](ARCHITECTURE.md). For module mechanics, read [docs/modules.md](docs/modules.md). If these differ from executable Nix code, verify the code and correct documentation only within task scope.

## Architectural invariants

- `flake/hosts.nix` builds `nixos-pc`, `nixos-lp`, and `nixos-server`; the module catalog determines which module roots are imported for desktop versus server.
- Put reusable system behavior in NixOS modules and reusable per-user behavior in Home Manager modules. Keep host-specific selection and settings in `hosts/<host>/profile.nix`, machine details in `configuration.nix`.
- Host-specific Home Manager settings are passed through `my.primaryUser.home.settings`; avoid directly duplicating user module configuration in a host.
- Module discovery imports individual `.nix` files recursively, **except** a directory containing `default.nix` is treated as one module. Do not manually import discovered modules from host profiles, or turn implementation helpers into unintentionally discovered modules.
- Preserve existing `my.system.*`, `my.user.*`, `my.desktop.*`, `my.hardware.*`, and `my.server.*` option organization. Before inventing a new option, look for an existing one.
- NixOS/Home Manager options should own packages and services; `config/` is the source for application dotfiles. Respect `lib/config-paths.nix` adapters and host-specific mappings.
- Do not replace intentional writable state with immutable links or destructive activation. Neovim's Home Manager activation copies source files while preserving a generated Matugen file; browser profiles, logins, and Skillshare resources also have mutable boundaries.

## Sensitive input changes

For source selection, new-host installation or deployment helpers, read
[docs/installation.md](docs/installation.md) and the
[migration contract](docs/public-private-migration.md). Keep my-nixos the sole
build/deployment root; do not bypass existing-host private-material guards or
commit a personal input override to the public lock. Check private repository
visibility before copying sensitive data and keep its commits/PR separate.

## Deployment, security, and data safety

- **Never** run `nixos-rebuild switch`, `boot`, activate a new generation, restart VPN/networking/SSH/display-manager services, alter firewall routes, or change live host state without explicit authorization. Ordinary non-activating evaluation/builds are allowed.
- The VPN is security-sensitive: the server is the Hide.me gateway; desktop clients use isolated WireGuard-over-Tailscale routing for selected apps. Preserve fail-closed isolation, DNS handling, provider separation, and recovery/rollback behavior. Read [docs/shared-vpn-gateway.md](docs/shared-vpn-gateway.md) and [docs/network-namespaces.md](docs/network-namespaces.md) before touching it.
- Commit only SOPS-encrypted secret documents and public key/certificate material. Never inspect, print, commit, or interpolate private keys, bootstrap tokens, credentials, or decrypted secrets into Nix store expressions. See [docs/sops.md](docs/sops.md).
- Treat server storage mounts, backups, authentication, and boot configuration as high risk. Do not assume all `/srv/*` paths are on `/srv/storage`; check `docs/server.md` and the Nix definitions.
- Never delete runtime profiles, caches, databases, secrets, or legacy configurations on the assumption that a Nix module no longer references them.

## Validation and delivery

- For documentation-only changes: check links and file paths against the repository, and run `git diff --check` where a checkout is available. Do not claim Nix tests passed unless they ran.
- For Nix edits: check formatting, perform targeted evaluation and/or a non-activating affected-host build. Broaden to every affected host for shared modules. `nix flake check --no-build` evaluates checks but does not execute them.
- For Neovim changes: inspect `tests/neovim/run.sh` and run relevant smoke checks when available; for VPN changes, use the dedicated `tests/network-namespaces/` checks and require live-activation approval separately.
- Running `nix fmt` may change unrelated files: review and discard unrelated formatting. Never silently commit unrelated changes.
- Do not claim a successful local build, runtime test, or host activation that was not performed. Report exactly what was checked and what needs human verification.
- Use scoped commits (`type: short description`). Work on a feature branch and open a PR unless the user explicitly requests direct commits to main.
- After completing a task, summarize changed files, preserved behavior, validations, and any deployment or manual follow-up needed. Avoid broad refactors or creating speculative helpers.

## Where to read next

- [Task-to-file routing](docs/task-routing.md): fastest entry point for common requests.
- [Architecture](ARCHITECTURE.md): flow, invariants, runtime ownership, host responsibilities.
- [Module conventions](docs/modules.md): discovery, scopes, option patterns, and enablement.
- [Neovim agent guide](docs/agents/neovim.md), [desktop agent guide](docs/agents/desktop.md), [networking agent guide](docs/agents/networking.md): focused subsystem boundaries and checks. Read only the one relevant to the task.
- Subsystem operational guides in `docs/` remain the detailed source for user-facing workflows and incident procedures.
