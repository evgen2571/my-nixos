# my-nixos

I use this repository for my PC, laptop, and server. It keeps their NixOS system
settings, Home Manager configuration, and application dotfiles together, with
shared modules for the features each machine needs.

You can adapt it to your own machines without my private repository, credentials,
or network services. Start with your own host definition: my existing profiles
contain hardware and service choices for real machines.

## Quick start

For a guided walkthrough, follow [installation on your own machine](docs/getting-started/installation.md).
If you already use NixOS, the short path is below. You'll need Git, Nix with
`nix-command` and `flakes` enabled, network access to public inputs, and a Linux
build environment for your target. The recorded command syntax uses Nix 2.34.8.

```sh
git clone https://github.com/evgen2571/my-nixos.git
cd my-nixos
cp -r templates/host hosts/my-host
```

Before evaluating, [prepare the host](docs/getting-started/installation.md#2-choose-hardware-features-and-first-access):
add its hardware configuration, choose boot/network settings, and configure your
username, SSH public key, firewall access, and administration policy. Then
[register `my-host`](docs/getting-started/installation.md#3-register-and-build)
in `flake/hosts.nix` with `secretSource = "none"` and the appropriate module profile.

```sh
git add hosts/my-host flake/hosts.nix
nix flake check --no-build --no-write-lock-file
nix build --no-link .#nixosConfigurations.my-host.config.system.build.toplevel --no-write-lock-file
```

These commands evaluate checks and build your system without activating it.
`--no-build` doesn't execute test programs. The template deliberately refuses an
incomplete first-access configuration; a successful build still doesn't prove
that your hardware boots or SSH works. Continue with the guide before installing.
For my existing three hosts, use the separate [production build and deployment workflow](docs/guides/deployment.md).

## What's included

| Host | What I use it for | Host choices |
| --- | --- | --- |
| `nixos-pc` | Niri/Noctalia development desktop, applications, and games | [PC profile](hosts/pc/profile.nix) |
| `nixos-lp` | Niri/Noctalia laptop, with laptop-specific hardware and power settings | [Laptop profile](hosts/laptop/profile.nix) |
| `nixos-server` | Self-hosted services, storage, and the shared VPN gateway | [Server profile](hosts/server/profile.nix) |

The module collection includes a Fish/tmux/Kitty workflow, Neovim development and
research tools, Zen Browser workspaces, and optional AI tools. The VPN routes
selected applications through an isolated server gateway; ordinary host traffic
keeps its own networking. You don't need to adopt all of these choices.

## Documentation

Start at the [documentation index](docs/index.md), or go directly to:

- [Installation](docs/getting-started/installation.md) and [customization](docs/guides/customization.md)
- [Maintenance and validation](docs/guides/maintenance.md)
- [Architecture](docs/concepts/architecture.md) and [module conventions](docs/development/modules.md)
- [Secrets and optional private inputs](docs/reference/secrets.md)
- [Troubleshooting](docs/troubleshooting/common-problems.md)

Coding agents start with [AGENTS.md](AGENTS.md).
