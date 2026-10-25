# My NixOS

These are the NixOS configs I use on my PC, laptop, and home server. I've been moving more and more of my setup into Nix, and this is where it ended up.

https://github.com/user-attachments/assets/c9d99e2b-1268-4ea9-a44f-61b3f40b204a

## What I use

- **Desktop:** Niri + Noctalia, Kitty, Zen
- **Dev:** Neovim, tmux
- **Server:** storage, a few services, and a VPN gateway
- **Secrets:** SOPS, with my personal stuff in a private repo

I also keep my [wallpapers](https://github.com/evgen2571/wallpapers) in a separate repo.

## Where things are

- [`hosts/`](hosts/README.md) — my machines and how to add yours
- [`modules/`](modules/README.md) — features you can enable or disable
- [`config/`](config/README.md) — app configs and dotfiles
- `docs/` — notes on [maintenance](docs/maintenance.md) and [secrets](docs/secrets.md)

## Want to try it?

This is my personal setup, so don't expect everything to work out of the box. Feel free to copy whatever you find useful.

If you want to try the whole thing, start with the [host guide](hosts/README.md). You don't need my private repo to get started.

**One thing to watch out for:** the host template has a locked password by default. Make sure you've set up authentication before installing, or you might lock yourself out. See the [installation checklist](templates/host/README.md#before-you-install).

## AI usage

I use AI coding tools for parts of this repo, but I review the changes myself.

## License

MIT. See [LICENSE](LICENSE).
