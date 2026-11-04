# Umbriel

The PC and laptop offer Umbriel and Niri, with Umbriel selected by default in the greeter.
Umbriel uses a scrolling layout and Noctalia. Enable the system session
with `my.desktop.umbriel.enable` and this personal config with
`my.primaryUser.home.settings.my.user.desktop.umbrielConfig.enable`.
The modules are discovered automatically. Noctalia Greeter selects Umbriel when
its system module is enabled; otherwise it keeps Niri as its default.

`config.toml` owns shared input, layout, and animations. Set
`my.user.desktop.umbrielConfig.profile` to `pc` (the default) or `laptop`.
Home Manager installs the selected `profiles/<profile>.toml` as `profile.toml`;
it owns outputs, named workspace order, and startup applications.
`binds.toml` carries the Niri shortcuts; `rules.toml` carries its application and
dialog rules, including exclusions that keep dialogs on their current workspace.
`scratchpads.toml` assigns the floating utilities below.

Animations use a subtle 98% window entrance over 140 ms and a 90 ms closing fade.
Movement, resizing, workspace switching, and overview use fast springs without
overshoot; moves and resizes share a curve to settle together. Scratchpads fade
over 140 ms, and focus borders change over 100 ms.

| Shortcut | Behavior |
| --- | --- |
| `Mod+Shift+Return` | Show/hide dropdown Kitty with the persistent `dropdown` tmux session |
| `Mod+M` | Show/hide music; launch Sonora when enabled, otherwise Pear Desktop |
| `Mod+E` | Show/hide Yazi in Kitty |
| `Mod+W` | Focus or launch Zen Browser on the `web` workspace |
| `Mod+N` | Focus the `study` workspace (legacy notes shortcut) |
| `Mod+S` | Focus the `study` workspace |
| `Mod+A` | Focus the `ai` workspace |
| `Mod+C` | Focus the `code` workspace |
| `Mod+G` | Focus the `gaming` workspace |
| `Mod+Shift+A` | Focus or launch Anki |
| `Mod+Shift+C` | Open the sesh project picker |
| `Mod+Shift+O` | Focus or launch Orca |
| `Mod+Shift+Space` | Park the focused window in the spare `stash` scratchpad |
| `Mod+Ctrl+Space` | Show/hide the stash |
| `Mod+Ctrl+Shift+Space` | Return a visible stashed window to its original workspace |

Scratchpads launch on demand, retain their windows while hidden, and appear on the
pointer's monitor. Toggling a visible pad on another monitor brings it there.
Music, dropdown, and Yazi windows launched normally join their corresponding pad.
Closing a dropdown window keeps tmux alive; hiding it also keeps Kitty alive.

The PC uses `web`, `chats`, and `ai` on `DP-1`, and `study`, `code`, and `gaming`
on `HDMI-A-1`, with the existing modes and positions. Music remains available
through its scratchpad. The `code` workspace uses
normal columns; the others default to tabs. Named workspaces persist alongside
Umbriel's dynamic empty workspaces. Number keys select positions on the current
output, as in Niri.

The laptop uses `web`, `code`, `study`, `chats`, `ai`, and `gaming` on `eDP-1`,
in that order, at 1920×1080 and 120 Hz. Both profiles start Lan Mouse, Wayscriber,
and Zen; only the PC starts Anki. Anki stays available through `Mod+Shift+A` on
both hosts. Shortcuts, application rules, scratchpads, and animations are shared.

Noctalia runs through its existing systemd service. Its built-in Umbriel template
writes `noctalia.toml`, which is optional until the first theme render. Home Manager
owns individual config files so generated theme files remain writable. Screen
sharing uses `xdg-desktop-portal-umbriel`; file pickers stay on GTK and the login
keyring remains available. Web, study, Dolphin, and chat shortcuts reuse an
existing window through Umbriel IPC before launching another.

Both hosts enable `my.user.desktop.skwdWall.enable` for Skwd-wall's picker and renderer.
`Mod+Y` and the wallpaper bar button run `skwd-wall-v2`; its daemon starts with
the graphical session and restores the last selected wallpaper. Images and videos
use `wallpapers.directory` (`~/pictures/wallpapers` on the PC).
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

Both hosts keep their Niri modules and config. Select Niri in the greeter to use
it, or disable both Umbriel options in the host's `profile.nix` to make Niri the
default again. The laptop disables Noctalia desktop widgets; existing GUI
overrides in `~/.local/state/noctalia/settings.toml` still take priority.
Keep a known-good generation and console access when first
trying the new session; the branch itself does not activate anything.

## Checks

```sh
just check --no-build
just build nixos-pc
just build nixos-lp
```

Evaluation and builds do not test NVIDIA rendering, monitor placement,
login, lock/unlock, live scratchpads, screenshots, or screen sharing.
