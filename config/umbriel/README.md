# Umbriel

The PC uses Umbriel with a scrolling layout and Noctalia. Enable the system session
with `my.desktop.umbriel.enable` and this personal config with
`my.primaryUser.home.settings.my.user.desktop.umbrielConfig.enable`.
The modules are discovered automatically. Noctalia Greeter selects Umbriel when
its system module is enabled; otherwise it keeps Niri as its default.

`config.toml` owns outputs, workspaces, input, layout, and animations.
`binds.toml` carries the Niri shortcuts; `rules.toml` carries its application and
dialog rules, including exclusions that keep dialogs on their current workspace.
`scratchpads.toml` assigns the floating utilities below.

| Shortcut | Behavior |
| --- | --- |
| `Mod+Shift+Return` | Show/hide dropdown Kitty with the persistent `dropdown` tmux session |
| `Mod+M` | Show/hide music; launch Sonora when enabled, otherwise Pear Desktop |
| `Mod+E` | Show/hide Yazi in Kitty |
| `Mod+Shift+Space` | Park the focused window in the spare `stash` scratchpad |
| `Mod+Ctrl+Space` | Show/hide the stash |
| `Mod+Ctrl+Shift+Space` | Return a visible stashed window to its original workspace |

Scratchpads launch on demand, retain their windows while hidden, and appear on the
pointer's monitor. Toggling a visible pad on another monitor brings it there.
Music, dropdown, and Yazi windows launched normally join their corresponding pad.
Closing a dropdown window keeps tmux alive; hiding it also keeps Kitty alive.

The PC retains `browser`, `chats`, `music`, and `anki` on `DP-1`, and `notes`,
`code`, and `gaming` on `HDMI-A-1`, with the existing modes and positions. `music`
remains available for windows restored from its pad. The `code` workspace uses
normal columns; the others default to tabs. Named workspaces persist alongside
Umbriel's dynamic empty workspaces. Number keys select positions on the current
output, as in Niri.

Noctalia runs through its existing systemd service. Its built-in Umbriel template
writes `noctalia.toml`, which is optional until the first theme render. Home Manager
owns individual config files so generated theme files remain writable. Screen
sharing uses `xdg-desktop-portal-umbriel`; file pickers stay on GTK and the login
keyring remains available. Browser, notes, Dolphin, and chat shortcuts reuse an
existing window through Umbriel IPC before launching another.

The PC enables `my.user.desktop.skwdWall.enable` for Skwd-wall's picker and renderer.
`Mod+Y` and the wallpaper bar button run `skwd-wall-v2`; its daemon starts with
the graphical session and restores the last selected wallpaper. Images and videos
use the existing `~/Pictures/Wallpapers` directory (`wallpapers.directory`).
Home Manager seeds `~/.config/skwd-wall-v2/config.json` once and leaves GUI settings,
caches, and saved wallpapers writable. Noctalia's wallpaper renderer is disabled;
existing GUI overrides in `~/.local/state/noctalia/settings.toml` still take priority.
Skwd's built-in Noctalia theme bridge keeps the shell and existing app templates
following the selected wallpaper.
The lock screen uses Noctalia's solid background unless a lock-screen image is set,
and greeter appearance sync no longer carries a desktop wallpaper.

## Differences from Niri

- Scratchpads replace music and dropdown focus-or-close behavior; Yazi also gets a
  scratchpad. Only one pad can be visible per output.
- `Alt+Tab` returns to the last focused window; `Alt+Shift+Tab` uses previous
  layout order. Umbriel has no matching per-application recent-window cycle for
  Niri's `Alt+grave` bindings.
- `Mod+Period` uses Umbriel's combined consume/expel action: it splits a window
  out of a stacked column but can join its neighbor when already alone.
- `Mod+Ctrl+R` sets half-height and `Mod+Ctrl+F` sets full column width.
  `Mod+Ctrl+C` centers the focused column. Niri's automatic height reset,
  expand-to-free-space, and center-visible-columns actions have no exact equivalent.
- Screenshot chords use Noctalia's region, focused-monitor, and focused-window
  capture. They follow Noctalia's screenshot directory and clipboard settings.
- Tab indicators, blur, and spring animations use Umbriel's rendering settings.
  Niri-only layer placement, overview shadow, notification, and screenshot UI
  animation settings have no direct equivalent and are omitted.

The laptop keeps its Niri modules and config. To return the PC to Niri in a future
configuration, disable both Umbriel options and re-enable both Niri options in
`hosts/pc/profile.nix`. Keep a known-good generation and console access when first
trying the new session; the branch itself does not activate anything.

## Checks

```sh
python3 -B config/umbriel/test-config.py
nix-build config/umbriel/test-module.nix --no-out-link
nix-build config/skwd-wall/test-module.nix --no-out-link
just check --no-build
just build nixos-pc
```

The module test evaluates enabled/disabled system and home settings, then validates
the installed TOML with the pinned Umbriel binary. The Python tests cover app and
dialog routing, scratchpads, shortcut coverage, app reuse, and IPC failure handling.
Builds and config validation do not test NVIDIA rendering, monitor placement,
login, lock/unlock, live scratchpads, screenshots, or screen sharing.
