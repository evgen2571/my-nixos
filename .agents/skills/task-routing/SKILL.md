---
name: task-routing
description: Find owning modules, host profiles, dotfiles, and verification commands for changes to my-nixos. Use before repository exploration or edits; load only the affected subsystem guidance.
---

# Task-to-file routing

Use this page to identify the **smallest relevant slice** of the repository. Open the first path, then inspect the adjacent owning module, host profile and referenced documentation only as needed. Do not recursively read unrelated subtrees to solve a local problem.

| Task | First place to look | Related context / check |
| --- | --- | --- |
| Enable/disable an existing app on a machine | `hosts/<host>/profile.nix` | Corresponding `modules/user-apps/` or `modules/user-ai/` module |
| Add a user application | `modules/user-apps/` | [Module conventions](../../../docs/development/modules.md), relevant host profiles |
| Add a system package/service | `modules/system-apps/`, `modules/system-services/` | Host profile and module-catalog scope |
| Change host boot/hardware | `hosts/<host>/configuration.nix` | `hardware-configuration.nix`, non-activating host build |
| Change flake inputs | `flake.nix`, `flake.lock` | All affected hosts; avoid incidental lockfile churn |
| Change module discovery/import behavior | `lib/module-catalog.nix`, `lib/module-discovery.nix` | [Module conventions](../../../docs/development/modules.md), desktop and server evaluation |
| Change Fish/tmux/Kitty workflow | `config/fish/`, `modules/user-dev/` | `lib/config-paths.nix` and workstation bundle |
| Change Neovim keybindings/editor UI | `config/nvim/lua/core/` | [Neovim agent guide](../../neovim.md), `config/nvim/lua/plugins/`, `tests/neovim/run.sh` |
| Change Neovim plugin or language setup | `config/nvim/lua/plugins/` | Plugin lockfile, `modules/user-dev/neovim/`, [Neovim guide](../../../docs/guides/neovim-research.md) |
| Change Niri shortcuts/layout | `config/niri/sub/binds.kdl` or `layout.kdl` | [Desktop agent guide](../../desktop.md), `config/niri/config.kdl`, `modules/user-desktop/niri/` |
| Change Niri window rules | `config/niri/sub/rules/` | `config/niri/config.kdl`, `lib/config-paths.nix` |
| Change PC/laptop Niri workspaces | `config/niri/sub/workspaces-pc.kdl` or `workspaces-laptop.kdl` | `modules/user-desktop/niri/config.nix` |
| Change Noctalia shell/theme | `config/noctalia/`, `modules/user-desktop/noctalia/` | Beware generated/runtime settings |
| Change greeter/login | `modules/desktops/noctalia-greeter.nix` | [Greeter guide](../../../docs/guides/noctalia-greeter.md), PAM and host profile |
| Change Zen workspaces/profile | `config/zen/profile.nix` | `config/zen/chatgpt-projects.nix`, `modules/user-apps/zen-browser.nix`, [Zen guide](../../../docs/guides/zen-browser.md) |
| Change Codex/Orca or CodeGraph integration | `modules/user-ai/` | [Skillshare](../../../docs/guides/skillshare.md), [CodeGraph](../../../docs/guides/codegraph.md), VPN runbook when routing changes |
| Change VPN namespace/gateway/launchers | `modules/system-services/network-namespaces/` | [Networking agent guide](../../networking.md), [Gateway](../../../docs/guides/shared-vpn-gateway.md), [primitives](../../../docs/reference/network-namespaces.md), `tests/network-namespaces/` |
| Source modes, templates, deployment preflight | `flake/hosts.nix`, `lib/secret-source.nix`, `modules/deployment/` | [Installation](../../../docs/getting-started/installation.md), `tests/migration/` |
| Change secrets/recipients | `modules/secrets.nix`, `hosts/<host>/secrets.nix` | selected repository recipient policy, [SOPS guide](../../../docs/reference/secrets.md) |
| Change server Docker, SSH, storage, Syncthing | `modules/server/`, `hosts/server/profile.nix` | [Server operations](../../../docs/guides/server.md), storage and access safety |
| Change flake checks or test harness | `flake/verification.nix`, `tests/` | `justfile`, target test fixtures |

## Validation selection

Choose checks based on **change impact**, not repository size:

| Scope | Baseline |
| --- | --- |
| Documentation | Verify relative links and referenced paths; `git diff --check` |
| One host/profile or app module | Format + targeted evaluation; non-activating build of that host where possible |
| Shared NixOS/Home Manager module | Evaluate/build all affected desktop/server profiles |
| Neovim configuration | Relevant editor smoke tests in `tests/neovim/` and manual UI checks as needed |
| VPN/systemd/network/security | Dedicated namespace tests, relevant host builds, and separately approved live deployment |
| Server storage/auth/boot | Non-activating server build and an explicit manual recovery plan |

For public-only checks, use `nix flake check --no-build --no-write-lock-file`.
To execute registered checks use `nix flake check --no-write-lock-file`.
Production host builds need the explicit private input from
[deployment](../../../docs/guides/deployment.md#build-without-activation).
Neovim smoke checks require locally provisioned plugins; inspect the harness first.
Do not assume all test tools exist in the development shell. Review formatting diffs.

## Documentation ownership

- [Human index](../../../docs/index.md): reader navigation and operational guides.
- [Architecture](../../../docs/concepts/architecture.md): ownership, invariants, and rationale.
- [Modules](../../../docs/development/modules.md): discovery and implementation patterns.
- [Source selection](../../../docs/reference/secrets.md): none/local/private and SOPS.
- [Deployment](../../../docs/guides/deployment.md): existing-host builds, guards, and recovery.
- [AGENTS.md](../../../AGENTS.md): essential agent rules; this skill routes tasks.
- `.agents/`: focused agent procedures, loaded only for the relevant task.
- `docs/archive/`: dated evidence and plans, with original limitations; never
  treat historical acceptance notes as current operating instructions.

Update incoming links when moving documentation. Keep each contract in one place.
