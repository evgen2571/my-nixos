# Task-to-file routing

Use this page to identify the **smallest relevant slice** of the repository. Open the first path, then inspect the adjacent owning module, host profile and referenced documentation only as needed. Do not recursively read unrelated subtrees to solve a local problem.

| Task | First place to look | Related context / check |
| --- | --- | --- |
| Enable/disable an existing app on a machine | `hosts/<host>/profile.nix` | Corresponding `modules/user-apps/` or `modules/user-ai/` module |
| Add a user application | `modules/user-apps/` | [Module conventions](modules.md), relevant host profiles |
| Add a system package/service | `modules/system-apps/`, `modules/system-services/` | Host profile and module-catalog scope |
| Change host boot/hardware | `hosts/<host>/configuration.nix` | `hardware-configuration.nix`, non-activating host build |
| Change flake inputs | `flake.nix`, `flake.lock` | All affected hosts; avoid incidental lockfile churn |
| Change module discovery/import behavior | `lib/module-catalog.nix`, `lib/module-discovery.nix` | [Module conventions](modules.md), desktop and server evaluation |
| Change Fish/tmux/Kitty workflow | `config/fish/`, `modules/user-dev/` | `lib/config-paths.nix` and workstation bundle |
| Change Neovim keybindings/editor UI | `config/nvim/lua/core/` | [Neovim agent guide](agents/neovim.md), `config/nvim/lua/plugins/`, `tests/neovim/run.sh` |
| Change Neovim plugin or language setup | `config/nvim/lua/plugins/` | Plugin lockfile, `modules/user-dev/neovim/`, [Neovim guide](neovim-research.md) |
| Change Niri shortcuts/layout | `config/niri/sub/binds.kdl` or `layout.kdl` | [Desktop agent guide](agents/desktop.md), `config/niri/config.kdl`, `modules/user-desktop/niri/` |
| Change Niri window rules | `config/niri/sub/rules/` | `config/niri/config.kdl`, `lib/config-paths.nix` |
| Change PC/laptop Niri workspaces | `config/niri/sub/workspaces-pc.kdl` or `workspaces-laptop.kdl` | `modules/user-desktop/niri/config.nix` |
| Change Noctalia shell/theme | `config/noctalia/`, `modules/user-desktop/noctalia/` | Beware generated/runtime settings |
| Change greeter/login | `modules/desktops/noctalia-greeter.nix` | [Greeter guide](noctalia-greeter.md), PAM and host profile |
| Change Zen workspaces/profile | `config/zen/profile.nix` | `config/zen/chatgpt-projects.nix`, `modules/user-apps/zen-browser.nix`, [Zen guide](zen-browser.md) |
| Change Codex/Orca or CodeGraph integration | `modules/user-ai/` | [Skillshare](skillshare.md), [CodeGraph](codegraph.md), VPN runbook when routing changes |
| Change VPN namespace/gateway/launchers | `modules/system-services/network-namespaces/` | [Networking agent guide](agents/networking.md), [Gateway](shared-vpn-gateway.md), [primitives](network-namespaces.md), `tests/network-namespaces/` |
| Source modes, templates, deployment preflight | `flake/hosts.nix`, `lib/secret-source.nix`, `modules/deployment/` | [Installation](installation.md), `tests/migration/` |
| Change secrets/recipients | `modules/secrets.nix`, `hosts/<host>/secrets.nix` | selected repository recipient policy, [SOPS guide](sops.md) |
| Change server Docker, SSH, storage, Syncthing | `modules/server/`, `hosts/server/profile.nix` | [Server operations](server.md), storage and access safety |
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

Useful commands (from the repository root):

```sh
nix flake check --no-build  # evaluate checks; do not execute them
nix flake check             # run registered checks, potentially expensive
just build-pc               # non-activating system build
just build-lp
just build-server
bash tests/neovim/run.sh    # requires locally provisioned Neovim/plugins
```

The `just` command needs to be installed separately if absent. Do not assume the Neovim smoke script or all test dependencies are available in a fresh development shell. `nix fmt` may format files outside task scope: inspect the diff.

For the proposed public/private repository split, see the
[M01 migration contract](public-private-migration.md). It is planning guidance,
the approved contract; implemented workflows are in [installation](installation.md).
Neither document authorizes deployment or publication.

## Documentation ownership

- [README](../README.md): project introduction, hosts and human quick start.
- [AGENTS.md](../AGENTS.md): agent process, guardrails, minimal completion criteria.
- [ARCHITECTURE.md](../ARCHITECTURE.md): design, import flow, invariants, state ownership and rationale.
- [modules.md](modules.md): code organization, module discovery/enablement and implementation patterns.
- **This page:** file routing and test selection, **not** a second source for architecture rules.
- Existing `docs/` subsystem guides: detailed runtime and troubleshooting procedures. Do not copy full operational guides into the root documents.
- `docs/agents/`: small agent-facing subsystem boundaries and task-specific checks; load only the relevant guide.
- `docs/archive/`: historical snapshots may predate deployment or contain incomplete acceptance notes. Check current source, running host state and runbooks before using them as operating instructions.

When moving or updating documentation, update incoming links and avoid maintaining duplicate explanations in multiple places.
