# Noctalia

Noctalia is the shell I use with Niri: bar, launcher, notifications, clipboard, and wallpaper picker.

Most defaults live in [`config.toml`](config.toml). The `*-common.toml` files are shared; `*-pc.toml` and `*-laptop.toml` handle differences between my desktops.

The wallpaper directory defaults to `~/Pictures/Wallpapers`. It's configurable through `programs.noctalia.settings.wallpaper.directory`; my wallpaper flake uses the same setting.

Theme colors are generated, including the files Niri, Kitty, and Neovim read. If a color change isn't showing up, check Noctalia's generated files instead of editing them by hand.

Some settings changed in the GUI stay in `~/.local/state/noctalia/settings.toml` and can override repo defaults. I keep that state writable.

In Niri, `Mod+Space` opens the launcher, `Mod+S` the control center, and `Mod+Comma` the settings.
