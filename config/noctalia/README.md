# Noctalia

Noctalia is the shell I use with Niri: bar, launcher, notifications, clipboard, and wallpaper picker.

Enable `my.user.desktop.noctalia.enable` for the shared setup. [`config.toml`](config.toml) keeps my appearance and behavior choices; everything else uses Noctalia's defaults. Battery and brightness widgets hide when their hardware is unavailable.

Override any setting through `programs.noctalia.settings`, including individual widgets and `bar.default.start`, `center`, and `end`. `my.user.desktop.noctalia.configFile` can replace the shared TOML. The old optional `profile` setting still accepts `pc` and `laptop` for compatibility.

Noctalia 5.2.1 uses pixel centers for desktop and lockscreen widgets. It supports resolution remapping, but has no edge anchors; an empty `output` selects the first available monitor. The PC includes [`widgets-pc.toml`](widgets-pc.toml) through `programs.noctalia.settings.include.files` to keep its clock, audio visualizer, and saved login-box placement. Other hosts use Noctalia's defaults and can place widgets in the GUI.

The wallpaper directory defaults to `~/Pictures/Wallpapers`. It's configurable through `programs.noctalia.settings.wallpaper.directory`; my wallpaper flake uses the same setting. Hurmit is installed with the shell. The custom Niri and Neovim theme templates run when their corresponding modules are enabled.

The PC uses [Skwd-wall](../umbriel/README.md) for wallpaper selection and rendering,
with the same directory. The laptop keeps Noctalia's wallpaper picker and renderer.

Theme colors are generated, including the files Niri, Kitty, and Neovim read. If a color change isn't showing up, check Noctalia's generated files instead of editing them by hand.

Settings changed in the GUI stay in `~/.local/state/noctalia/settings.toml` and override repo defaults. I keep that state writable. Activation removes obsolete GUI overrides, including the unsupported timer desktop widget, after backing up the settings. The Sonora community theme needs the app to be launched once before Noctalia can apply it.

In Niri, `Mod+Space` opens the launcher, `Mod+S` the control center, and `Mod+Comma` the settings.

Config checks: `nix-build config/noctalia/test-config.nix --no-out-link` and `python3 config/noctalia/test-prune-stale-settings.py`.
