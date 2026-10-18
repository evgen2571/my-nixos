# my-nixos

My NixOS configuration for a desktop PC, laptop, and server. The desktops use Niri
and Noctalia; the server runs self-hosted services and a VPN gateway. This is my
working infrastructure. You can borrow parts or adapt it to your own hardware.

## Find what you need

| Task | Guide |
| --- | --- |
| Use or customize the desktop | [Niri](docs/apps/niri.md), [Noctalia](docs/apps/noctalia.md), [Kitty](docs/apps/kitty.md) |
| Work in the editor | [Neovim](docs/apps/neovim.md), [competitive programming](docs/apps/competitive-programming.md) |
| Configure the browser | [Zen](docs/apps/zen-browser.md) |
| Manage agent tools | [Skillshare](docs/apps/skillshare.md), [CodeGraph](docs/apps/codegraph.md) |
| Find the file to edit | [Configuration map](docs/reference/configuration.md), [customization](docs/operations/customization.md) |
| Build, update, or recover a host | [Deployment](docs/operations/deployment.md), [maintenance](docs/operations/maintenance.md) |
| Manage server data or VPN access | [Server](docs/operations/server.md), [VPN](docs/operations/vpn.md) |
| Handle credentials and private settings | [Secrets and private inputs](docs/operations/secrets.md) |

[All guides](docs/README.md) include login/greeter and troubleshooting.
[Architecture](docs/reference/architecture.md) explains how the pieces fit together;
[module conventions](docs/reference/modules.md) cover adding or changing features.

## Setup and installation

You need Nix with flakes enabled. Clone the repository and enter its development
shell:

```sh
git clone https://github.com/evgen2571/my-nixos.git
cd my-nixos
nix develop
nix flake check --no-build --no-write-lock-file
```

The last command evaluates checks; it does not run their test programs. A clean
clone can evaluate the three existing hosts, but building or deploying them
requires the maintainer's private input. Their hardware and accounts describe
real machines. To install on another machine, follow [installation](docs/operations/installation.md)
and start from [the host template](templates/host/README.md).

For a maintainer build, explicitly select the private checkout:

```sh
private_checkout=$(git -C ../my-nixos-private rev-parse --show-toplevel)
nix build .#nixosConfigurations.nixos-pc.config.system.build.toplevel \
  --override-input private "git+file://$private_checkout" --no-write-lock-file --no-link
```

Use `nixos-lp` or `nixos-server` for the other hosts. This builds without activating.
Read [deployment](docs/operations/deployment.md) before switching a real host;
networking, boot, credentials, and storage changes need a recovery path.

## Hosts

| Output | Machine | Feature selection |
| --- | --- | --- |
| `nixos-pc` | Desktop workstation | [PC profile](hosts/pc/profile.nix) |
| `nixos-lp` | Laptop | [Laptop profile](hosts/laptop/profile.nix) |
| `nixos-server` | Services and shared VPN gateway | [Server profile](hosts/server/profile.nix) |

Select features in `hosts/<host>/profile.nix`, implement them in `modules/`, and
edit application sources in `config/`. Some applications keep generated themes,
logins, or other writable state; check their guide before changing deployment.

For coding agents, [AGENTS.md](AGENTS.md) routes tasks to repository skills.
