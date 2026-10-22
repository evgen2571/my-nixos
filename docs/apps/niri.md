# Niri

Niri arranges tiled windows in scrolling columns. `Mod` is the desktop modifier
(Super in a normal session).

| Keys | Action |
| --- | --- |
| `Mod+H/L` | Focus column; cross to the adjacent monitor at the column boundary |
| `Mod+J/K` | Focus window down/up; switch workspace at the column boundary |
| `Mod+Shift+H/L` | Move a column left/right; cross to the adjacent monitor at the edge |
| `Mod+Shift+J/K` | Move the focused window directly to the next/previous workspace |
| `Mod+Ctrl+H/L` | Focus adjacent monitor directly |
| `Mod+Ctrl+J/K` | Focus next/previous workspace directly |
| `Mod+Alt+H/L` | Decrease/increase column width by 5% |
| `Mod+Alt+J/K` | Decrease/increase window height by 5% |
| `Mod+Ctrl+Shift+H/L` | Move a whole column to the adjacent monitor directly |
| `Mod+Ctrl+Shift+J/K` | Move a whole column to the next/previous workspace directly |
| `Mod+Page_Down/Page_Up` | Focus next/previous workspace; add Shift to reorder workspaces |
| `Mod+1` through `Mod+9` | Focus numbered workspace; add Shift to move a column there |
| `Mod+R` / `Mod+Shift+R` / `Mod+Ctrl+R` | Cycle column widths / window heights / reset height |
| `Mod+Z` / `Mod+Shift+Z` | Maximize window to edges / maximize column |
| `Mod+Alt+Space` / `Mod+Shift+V` | Toggle floating / focus floating versus tiled windows |
| `Mod+Shift+F` / `Mod+Q` | Fullscreen / close window |

Horizontal Shift movement uses `move-column-left-or-to-monitor-left` and its
right counterpart. Shift+J/K sends the focused window to another workspace.
Ctrl+Mod+HJKL retains direct monitor/workspace focus; Ctrl+Alt+Mod+HJKL is unbound.
Arrows mirror HJKL for focus, Shift movement, and Alt sizing. Direct column
movement uses Ctrl+Shift rather than Alt+Shift, which switches keyboard layouts.
The old U/I navigation groups and monitor arrow chords are removed. Home/End
still focus the first/last column; Ctrl+Home/End move a column to those positions.
The existing minus/equal bindings retain coarse 10% sizing.

| Keys | Action |
| --- | --- |
| `Mod+Return` / `Mod+Shift+Return` | Kitty / dropdown terminal (close and reopen its tmux session) |
| `Mod+Space` / `Mod+S` | App launcher / control center |
| `Mod+Comma` | Noctalia Settings |
| `Mod+Shift+P` | Lock and suspend (moved from `Mod+Alt+L`) |
| `Mod+C` | Project-session picker |
| `Mod+F` / `Mod+E` / `Mod+Shift+E` | Browser / Yazi / Dolphin |
| `Mod+Shift+D` | Toggle Wayscriber screen annotation |
| `Mod+Tab` | Workspace overview |
| `Alt+Tab` / `Alt+grave` | Cycle windows on this output / windows of the same app |
| `Print` / `Ctrl+Print` / `Alt+Print` | Screenshot selection / screen / window |

The full [binding file](../../config/niri/sub/binds.kdl) also covers media,
brightness, mouse wheel navigation and app launchers. Niri screenshots use
`~/screenshots`; Noctalia's screenshot directory is configured separately.

[Wayscriber](https://github.com/devmobasa/wayscriber) starts in daemon mode with
the Niri session on both desktops. `Mod+Shift+D` shows or hides its overlay.

## Focus-or-launch and the dropdown

The [focus-or-launch helper](../../config/niri/scripts/focus-or-launch) is still
needed to select an application by app ID/title or launch it. It uses native
`focus-window` after selecting the focused matching window, or otherwise the most
recently focused match (window ID breaks ties). An IPC error aborts without
launching a duplicate. Browser, music, chat, notes, and file-manager shortcuts
only focus or launch; pressing one while its application is focused never closes it.

Niri 26.04 has no native hide/minimize action. The dropdown explicitly uses
`--close-focused`: focus a matching terminal if present, close that Kitty window
if it is focused, or launch it if absent. The named `dropdown` tmux session keeps
its shell and programs running after the terminal closes; opening again attaches
to that session. Kitty itself is recreated. `--toggle` is no longer accepted.
This is not a hide operation and must not be used for persistent GUI applications.
No scratch workspace or offscreen hiding mechanism is introduced.

## Changing the desktop

[config/niri/config.kdl](../../config/niri/config.kdl) includes the files under
[sub/](../../config/niri/sub). Edit `binds.kdl` for shortcuts, `layout.kdl` for
sizing, `input.kdl` for input, and `rules/apps/` for application policies.
`noctalia.kdl`, `noctalia-layout.kdl`, and `noctalia-dropdown.kdl` are generated
siblings, not repository-owned runtime state.

The built-in Noctalia Niri template provides focus-ring, border, tab, and insert
colors. A small [layout template](../../config/noctalia/templates/niri-layout.kdl)
adds the workspace surface color; until it renders, the background is neutral
and tab indicators follow focus-ring colors. The layout/dropdown includes are
optional before first render; the existing built-in `noctalia.kdl` is required.
The dropdown shadow uses a hex alpha suffix, supported by both Noctalia's
renderer and Matugen. Native blur and the layer-shell rules remain enabled.

PC and laptop have separate named-workspace files. The
[Niri Home Manager module](../../modules/desktop/niri/home.nix) selects
one through `my.user.desktop.niriConfig.workspaceProfile` and installs it as
`~/.config/niri/sub/workspaces.kdl`. Change host selection in its profile.
The PC spreads workspaces across two outputs; the laptop uses its internal
output. Numbered bindings follow each profile's workspace order.

The `code` workspace has a separately reviewable layout trial on all profiles:
new columns use `normal` display and a 50% default width. Editor terminals and
GUI editors routed there opt out of automatic maximization, allowing two editor
columns side by side. The temporary project picker remains maximized. Browser,
notes, gaming and other application maximization policies are unchanged, as are
the global width/height presets. Existing columns/windows may retain their prior
mode/size: `Mod+W` toggles column display and `Mod+Z` toggles maximization.
This trial is in its own commit so it can be omitted or reverted independently
of the navigation, Settings, launcher, and authentication fixes. It has syntax
and rule-policy coverage, but still needs visual acceptance on both desktops.

`focus-follows-mouse`, `warp-mouse-to-focus`, and
`honor-xdg-activation-with-invalid-serial` remain unchanged. Changing their
interaction needs keyboard/mouse and tray/notification activation tests first;
new upstream activation policies must also be supported by the packaged version.

## Application windows and known limits

Noctalia Settings matches both `^dev\.noctalia\.Noctalia$` and
`^Noctalia Settings$`. It opens focused and floating at 52% width and 65% height,
without a workspace/output target, maximization or fullscreen. New floating
windows center on the current monitor by default. Niri remembers a window's last
floating position after it moves: showing an existing Settings window again does
not guarantee recentering. Close and create a new window for an opening-rule test.
The rule does not match other Noctalia windows or layer-shell panels.

Dolphin's main file browser opens floating at 62% width and 70% height.
Configure, Configure Language, Configure Toolbars, and file Properties windows
use 42% width and 55% height, without a workspace target or fixed position.
These rules match the observed English titles and Dolphin's app ID; other
dialog titles retain the file-browser defaults. Close and reopen dialogs to
test the opening sizes. Applications can enforce a larger minimum size.

The [mpv module](../../modules/apps/mpv.home.nix) sets audio/video MIME defaults;
the [qimgv module](../../modules/apps/qimgv.home.nix) sets image defaults on both
desktops. Associations list concrete MIME types because `audio/*`, `video/*`,
and `image/*` are not wildcard defaults. Add new formats to the owning module.

Dolphin also needs an XDG application menu for KDE's service index to discover
the installed desktop entries. Its module supplies `menus/applications.menu`;
without it, even valid MIME defaults can fall through to the application chooser.
The KDE Qt platform theme calls the KDE portal's chooser directly, so Niri also
installs that backend. The configured GTK file picker and GNOME screen-sharing
backend keep their existing priority. A missing chooser can produce
`Couldn't get reply` and `The name is not activatable` when opening files.
After rebuilding, log out and back in, then reopen Dolphin and test file opening.
The `dolphin-open-files` flake check exercises KDE's launcher with isolated
desktop entries and MIME defaults, rather than only querying `xdg-mime`.

Both desktops enable UDisks2 for Dolphin's device discovery. Dolphin's launcher
also exposes the PipeWire library to Qt Multimedia's runtime loader, without
changing the library path for the rest of the session. JPEG decoder warnings
about `0x89 0x50` mean PNG data reached a JPEG reader; this may involve a file or
an embedded preview/thumbnail and does not by itself establish image corruption.

Personal sidebar pins can be [declared through the private input](dolphin.md),
while the live Places file stays writable for Dolphin.

qimgv opens focused and floating at 70% width and height, centered on the monitor
for a new window. Close and reopen existing windows to test the rule.
Open one image, then use Left/Right or the mouse wheel to browse its folder in
the same window; `qimgv ~/downloads` opens a folder directly. qimgv 1.0.3 has no
single-instance option, tabs, or command-line collection of selected files.
Opening more files from Dolphin still starts separate qimgv windows.

Main Telegram and Vesktop windows open on `chats`; their other windows float
without a workspace target. Telegram media retains its larger size and explicit
initial-fullscreen override. Steam utilities, observed Prism dialogs, and OBS
Settings stay outside main-window workspace routing. Zen PiP floats. Deliberate
game fullscreen and OBS projector fullscreen requests remain allowed.

Editor-terminal routing requires Kitty/Foot with the exact title `editor`;
an unrelated application's title containing that word does not route to `code`.
The file-manager title also requires Kitty. Anki's known dialog titles are
excluded from the main-window rule, float only for Anki, and have no workspace
target. Separate `match` lines are ORed in Niri; app ID and title belong on the
same line when both are required.

Outside the code-editor layout trial, observed application rules and main-window
maximization remain in place.
Steam localized utilities, Prism Edit Instance/Accounts/logs, OBS
filters/properties/projectors, Zen independent auth/extension windows, Obsidian
localized dialogs, and Telegram direct calls still need targeted observations.
Some UIs are panels within a window. Do not invent title matches for them.
The global Open/Save/authentication-title fallback is retained until prompt
app IDs can be checked safely. Title changes after opening cannot retroactively
undo initial workspace routing, and calls can share main-window title signatures.

## Authentication

The [Niri NixOS module](../../modules/desktop/niri/nixos.nix) starts the Polkit
GNOME agent through the systemd user service, tied to `graphical-session.target`
with failure restart. Compositor startup no longer spawns another agent;
Noctalia's own Polkit agent stays disabled on both desktop profiles.

Read-only checks:

```sh
systemctl --user status polkit-gnome-authentication-agent-1.service
pgrep -af polkit-gnome-authentication-agent-1
```

The current PC service was active with a successful process status and one agent
at inspection time. A real authentication prompt and a fresh-login startup check
remain necessary; no service restart is part of source validation.

## Verification

The [upstream bindings](https://niri-wm.github.io/niri/Configuration%3A-Key-Bindings.html),
[named workspace layouts](https://niri-wm.github.io/niri/Configuration%3A-Named-Workspaces.html#layout-config-overrides),
and [floating position semantics](https://niri-wm.github.io/niri/Configuration%3A-Window-Rules.html#default-floating-position)
were checked against the actions/configuration accepted by packaged Niri 26.04.
No navigation script or new application dependency is needed.

```sh
python3 tests/niri/focus-or-launch.py
python3 tests/niri/config.py
python3 tests/niri/window-titles.py
python3 tests/niri/validate.py --generated-dir "$HOME/.config/niri"
nix build .#checks.x86_64-linux.niri-config .#checks.x86_64-linux.niri-host-profiles --no-link
```

The launcher tests mock IPC and never control the desktop. Classification tests
cover scoped rules, preserved application policies, modifier conflicts, and
binding actions. `validate.py` copies the complete default/PC/laptop trees into
temporary directories, retains the current built-in Noctalia colors, renders the
custom Niri templates in dark/light modes, and checks optional-include fallback.
The Nix check instead renders the pinned Noctalia package's built-in template
as well. Neither path activates or changes the running configuration.

Desktop acceptance after an authorized deployment still needs:

- HJKL focus at column/monitor/workspace boundaries, horizontal Shift column movement,
  vertical Shift window transfers, Ctrl direct focus, and Alt 5% sizing.
- Two physical PC monitors and the single laptop output, including mouse focus/warp interaction.
- Noctalia Settings opening focused, centered, and floating, and reopening a moved window.
- A Polkit prompt, focus-or-launch with several matching windows, and closing/reopening the tmux dropdown.
- Dialog opening after moving its parent, focus return, PiP/media viewers, game/projector fullscreen, and tray/notification activation.

Configuration notifications are disabled, so inspect `niri validate` output
explicitly. Read-only `niri msg --json windows` and `workspaces` can help; dimensions
alone do not establish fullscreen state. Keep private titles out of reports and
fixtures. Evaluation and syntax checks do not establish desktop behavior.

## X11 applications and Steam

The Niri system module installs `xwayland-satellite`; Niri's built-in integration
owns its startup and allocates `DISPLAY`. Avoid a competing manual startup,
hard-coded display number, or global environment override.

Post-deployment laptop Steam acceptance remains open. After an authorized
deployment and fresh Niri login, check satellite startup on demand, `DISPLAY`
in new Fish/Kitty processes and the user systemd environment, then open Steam
from both Kitty and the Noctalia desktop entry. Confirm a visible interactive
window, another X11 app and a Wayland app. Missing satellite was an identified
problem; an additional Steam runtime problem has not been ruled out. Evaluation
or a build cannot close this check.
