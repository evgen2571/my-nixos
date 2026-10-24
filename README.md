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

Follow [the host guide](hosts/README.md) to create your machine's configuration,
pick features, and check the build before installing. It includes a small Niri
desktop example. You'll need Nix with flakes enabled.

You can start without a private repository or encrypted secrets. Leave services
that need credentials disabled until you've set up your own.

This repo has no test suite. Evaluation catches configuration errors; a host build checks its packages and deployment guards. See [updates and recovery](docs/maintenance.md) for build commands and manual checks.

For the actual installation and partitioning, use the [NixOS manual](https://nixos.org/manual/nixos/stable/#sec-installation).
