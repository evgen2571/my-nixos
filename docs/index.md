# My NixOS setup

I keep my PC, laptop, and server in one repository. If you'd like to use parts
of it, start with your own host and add features as you need them. You don't
need my private repository or services.

## Get started

- [Install on your own machine](getting-started/installation.md): choose a host,
  prepare hardware and first access, build, then install.
- [Customize your host](guides/customization.md): choose features, edit application
  settings, and add modules.
- [Maintain and check your configuration](guides/maintenance.md): routine changes,
  input updates, validation, and recovery.

## Understand the setup

- [Architecture and state ownership](concepts/architecture.md)
- [Module discovery and implementation](development/modules.md)
- [Secrets and source selection](reference/secrets.md): no secrets, local SOPS,
  or an optional private input
- [Personal metadata boundaries](reference/personal-metadata.md)
- [Shared PC/laptop feature selections](reference/desktop-host-defaults.md)

## Operate existing hosts

- [Production builds, deployment, restore, and rollback](guides/deployment.md)
- [Server storage, services, and backups](guides/server.md)
- [Shared VPN gateway and recovery](guides/shared-vpn-gateway.md)
- [Network namespace implementation and authentication](reference/network-namespaces.md)
- [Troubleshoot builds, access, and applications](troubleshooting/common-problems.md)

## Applications and desktop

- [Neovim development, research, and keybindings](guides/neovim-research.md)
- [Neovim configuration ownership](reference/neovim-ownership.md)
- [Competitive programming](guides/competitive-programming.md)
- [Zen Browser profiles and workspaces](guides/zen-browser.md)
- [Noctalia greeter, appearance, and keyring](guides/noctalia-greeter.md)
- [Optional KDE Plasma workflow](guides/kde-plasma.md)
- [Skillshare and writable agent resources](guides/skillshare.md)
- [CodeGraph package, indexes, and MCP setup](guides/codegraph.md)

## Historical records

[The archive](archive/README.md) keeps dated migration plans, audits, and test
results with their original scope and limitations. Use the current guides for
operating instructions. Coding agents start at [AGENTS.md](../AGENTS.md).
