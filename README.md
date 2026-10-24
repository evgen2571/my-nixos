# my-nixos

These are the NixOS configs I use on my PC, laptop, and home server. I've been moving more and more of my setup into Nix, and this is where it ended up.

My desktops use **Niri + Noctalia**. I mostly work in **Kitty, tmux, and Neovim**, with Zen as my browser. The server handles storage, a few services, and a VPN gateway. There's a lot of personal stuff around the edges, so I wouldn't copy an entire host and expect it to work on another machine.

This isn't an installer or a polished starter kit. Feel free to borrow a module, copy some dotfiles, or make your own host with the same setup.

## Where things are

- [`hosts/`](hosts/README.md) — my machines and how to add yours
- [`modules/`](modules/README.md) — packages, services, and Home Manager options
- [`config/`](config/) — the actual app configs: [Niri](config/niri/README.md), [Noctalia](config/noctalia/README.md), [Neovim](config/nvim/README.md), [Zen](config/zen/README.md)
- [`docs/`](docs/README.md) — notes on secrets, updates, and recovery

## Trying it on your machine

Start with [the host template](hosts/README.md), not one of my existing hosts. You can run without a private repository or any encrypted secrets; just leave services that need credentials disabled.

You'll need Nix with flakes enabled. Check that the configurations evaluate before building your host:

```sh
nix flake check --no-build --no-write-lock-file
```

This repo has no test suite. Evaluation catches configuration errors; a host build checks its packages and deployment guards. See [updates and recovery](docs/maintenance.md) for build commands and manual checks.

For the actual installation and partitioning, use the [NixOS manual](https://nixos.org/manual/nixos/stable/#sec-installation). I only document the parts specific to this repo.

The desktop and Neovim pages are also where I'll put short screen recordings of the real setup. I don't plan to make a separate showcase for my browser spaces.
