# My NixOS

https://github.com/user-attachments/assets/c9d99e2b-1268-4ea9-a44f-61b3f40b204a

These are the NixOS configs I use on my PC, laptop, and home server. I've been moving more and more of my setup into Nix, and this is where it ended up.

My desktops run Niri + Noctalia, with Zen as my browser and Kitty as my terminal. I do most of my development in tmux and Neovim. The server handles storage, services, and a VPN gateway.

I keep my wallpapers in [a separate repo](https://github.com/evgen2571/wallpapers).

## Where things are

- [`hosts/`](hosts/README.md): my machines and how to add yours
- [`modules/`](modules/README.md): optional features and their settings
- [`config/`](config/README.md): app configs and my terminal workflow

For day-to-day changes, see [maintenance and recovery](docs/maintenance.md).
Private inputs and encrypted credentials are covered in [secrets](docs/secrets.md).

To use this setup on your machine, start with [the host guide](hosts/README.md).
You can choose your own features and start without a private repository.
