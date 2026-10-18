# my-nixos

Personal, multi-host NixOS configuration built with flakes and Home Manager. The same repository manages a desktop PC, a laptop, and a server; each host selects reusable features instead of maintaining an independent configuration.

## Hosts

| Flake output | Purpose | Entry point |
| --- | --- | --- |
| `nixos-pc` | Main Niri/Noctalia workstation | [hosts/pc/](hosts/pc/) |
| `nixos-lp` | Niri/Noctalia laptop | [hosts/laptop/](hosts/laptop/) |
| `nixos-server` | Self-hosted services and shared VPN gateway | [hosts/server/](hosts/server/) |

The configuration is organized as **flake assembly → host choices → reusable NixOS/Home Manager modules → source dotfiles and runtime state**.

- `flake.nix` and `flake/`: inputs, host outputs, formatting, checks, and development shell.
- `hosts/<host>/configuration.nix`: machine identity, boot, hardware-related settings, and base imports.
- `hosts/<host>/profile.nix`: features and host-specific options.
- `modules/system-*`, `modules/desktops/`, `modules/hardware/`, `modules/server/`: NixOS behavior.
- `modules/user-*`: Home Manager behavior.
- `config/`: source configuration for Niri, Neovim, Fish, Zen, Noctalia, and other applications.
- `lib/module-catalog.nix` and `lib/module-discovery.nix`: module availability, not feature enablement.

See [ARCHITECTURE.md](ARCHITECTURE.md) for the actual import graph and ownership rules.

## Sensitive inputs and installation

This repository remains the sole build/deployment root. A clean clone evaluates
all three hosts without credentials using the empty `templates/private` input.
New hosts can use no secrets or their own single-repository SOPS; the existing
production hosts require an explicit private override and refuse secretless builds.
Start with [installation and source modes](docs/installation.md),
[templates/host](templates/host/README.md), or
[templates/private](templates/private/README.md).

## Working with the configuration

On a NixOS machine with flakes enabled, clone the repository and work from its root:

```sh
nix develop
nix fmt
nix flake check --no-build
private_checkout=$(git -C ../my-nixos-private rev-parse --show-toplevel)
just build-pc --override-input private "git+file://$private_checkout" --no-write-lock-file
```

Replace `build-pc` with `build-lp` or `build-server` as appropriate. `just` is a separate prerequisite if not already installed; equivalent commands are in [justfile](justfile). The build targets produce a system closure **without activating it**. `nix flake check --no-build` only evaluates checks; it is not proof that their test programs passed. Run `nix flake check` when the full checks are warranted and prerequisites are available.

Deployment is a distinct, intentional step performed **on the matching host**:

```sh
sudo nixos-rebuild switch --flake .#nixos-pc \
  --override-input private "git+file://$private_checkout" --no-write-lock-file
```

Do not deploy a changed networking, boot, security, or storage configuration without planning for recovery. NixOS generations roll back system configuration, not necessarily application databases, mutable secrets, or other runtime data.

## Making a change

For an existing application, find its module, then edit its source configuration in `config/` if applicable. To select or deselect a feature on a machine, use the matching `hosts/<host>/profile.nix`. For a new feature, follow [module conventions](docs/modules.md) rather than adding arbitrary imports.

Not every application setting is fully declarative: login sessions, generated themes, writable editor configuration, and agent resources have explicit runtime-state boundaries. Read the relevant subsystem guide before changing activation or file ownership.

## Documentation

| Read this | For |
| --- | --- |
| [ARCHITECTURE.md](ARCHITECTURE.md) | System design, ownership, invariants, and rationale |
| [docs/task-routing.md](docs/task-routing.md) | Which files to open for a specific task |
| [docs/modules.md](docs/modules.md) | Module discovery, option patterns, and host enablement |
| [docs/agents/](docs/agents/) | Focused Neovim, desktop, and networking guides for coding agents |
| [AGENTS.md](AGENTS.md) | Repository-specific coding-agent rules |
| [docs/server.md](docs/server.md) | Server operations and persistent data |
| [docs/shared-vpn-gateway.md](docs/shared-vpn-gateway.md) | Server-only VPN gateway and deployment safeguards |
| [docs/network-namespaces.md](docs/network-namespaces.md) | Namespace implementation and troubleshooting |
| [docs/sops.md](docs/sops.md) | Encrypted secrets and recipient management |
| [docs/neovim-research.md](docs/neovim-research.md) | Neovim workflow and keybindings |
| [docs/zen-browser.md](docs/zen-browser.md) | Zen profile/workspace behavior |
| [docs/skillshare.md](docs/skillshare.md) | Runtime-managed skills and agent resources |

Other focused guides in `docs/` cover competitive programming, CodeGraph, KDE, Noctalia greeter, and recorded Neovim validation. Historical migration material is kept under `docs/archive/`, separate from current operations.

**For agents:** start with [AGENTS.md](AGENTS.md), then follow [task routing](docs/task-routing.md); do not load every subsystem guide for a small task.
