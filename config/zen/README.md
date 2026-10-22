# Zen

Nix installs Zen and applies a few shared browser defaults, the compact-mode shortcut (Ctrl + backtick), and Sine integration.

My **spaces, pins, routes, and workspace IDs are personal**, so they belong in `my-nixos-private`, not in this directory. I don't ship a copy of my browser layout.

`my.user.apps.zenBrowser.profilePath` selects an existing profile directory. Leave it `null` if you don't want Nix to manage a browser profile. You can find the directory in `about:profiles`.

If you adopt an existing profile, close Zen and back up `~/.config/zen` first. Keep your existing space and pin UUIDs: making up new ones creates new browser items. Sessions, passwords, extensions, and history stay browser-owned and writable.
