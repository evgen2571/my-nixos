# Niri

Niri arranges tiled windows in scrolling columns. `Mod` is the desktop modifier
(Super in a normal session). Start with these bindings:

| Keys | Action |
| --- | --- |
| `Mod+Return` / `Mod+Shift+Return` | Kitty / toggle dropdown terminal |
| `Mod+Space` / `Mod+S` | App launcher / control center |
| `Mod+C` | Project-session picker |
| `Mod+F` / `Mod+E` / `Mod+Shift+E` | Browser / Yazi / Dolphin |
| `Mod+Tab` | Workspace overview |
| `Mod+H/J/K/L` or arrows | Focus adjacent column/window |
| Add Shift to focus bindings | Move column/window |
| `Mod+1` through `Mod+9` | Focus numbered workspace; add Shift to move a column there |
| `Mod+U/I` | Next/previous workspace; add Ctrl to move a column there |
| `Mod+R` / `Mod+Shift+R` | Cycle column widths / window heights |
| `Mod+Z` / `Mod+Shift+Z` | Maximize window to edges / maximize column |
| `Mod+Alt+Space` / `Mod+Shift+V` | Toggle floating / focus floating versus tiled windows |
| `Mod+Shift+F` / `Mod+Q` | Fullscreen / close window |
| `Alt+Tab` / `Alt+grave` | Cycle windows on this output / windows of the same app |
| `Print` / `Ctrl+Print` / `Alt+Print` | Screenshot selection / screen / window |

The full [binding file](../../config/niri/sub/binds.kdl) also covers media,
brightness, monitor movement, app launchers and manual sizing. Niri screenshots
use `~/screenshots`; Noctalia's screenshot directory is configured separately.

## Changing the desktop

[config/niri/config.kdl](../../config/niri/config.kdl) includes the files under
[sub/](../../config/niri/sub). Edit `binds.kdl` for shortcuts, `layout.kdl` for
sizing, `input.kdl` for input, and `rules/apps/` for application policies.
`noctalia.kdl` and `noctalia-dropdown.kdl` are generated theme inputs.

PC and laptop have separate named-workspace files. The
[Niri Home Manager module](../../modules/user-desktop/niri/config.nix) selects
one through `my.user.desktop.niriConfig.workspaceProfile` and installs it as
`~/.config/niri/sub/workspaces.kdl`. Change host selection in its profile.
The PC spreads workspaces across two outputs; the laptop uses its internal
output. Numbered bindings follow each profile's workspace order.

Validate a complete host configuration tree with `niri validate`; validating one
isolated rule file does not check its includes or interactions. Configuration
notifications are disabled, so check validation output explicitly.

## Application windows and known limits

Main Telegram and Vesktop windows are intended to open on `chats`; their other
windows float without a workspace target. Telegram media has its own larger
size and initial-fullscreen override. Steam utilities, observed Prism dialogs,
and OBS Settings are excluded from main-window workspace routing. Zen PiP has
its own floating rule. Deliberate video/projector/game fullscreen remains allowed.

Rules distinguish windows using app IDs and titles. Future titles, translations,
or calls named like a main-window signature can change classification. Opening
rules cannot correct placement after a title changes. Existing global title
rules can also interfere: Anki-like prefixes can route unrelated dialogs to
`anki`, and lowercase `editor` in a title can route a window to `code`. Preserve
rule order while investigating these interactions.

The auxiliary-window work remains incomplete. Steam localized utilities, Prism
Edit Instance/Accounts/logs, OBS filters/properties/projectors, Zen independent
auth/extension windows, and Telegram direct calls need targeted observations.
Some UIs may be panels within a window. Do not invent title matches for them.

Run `python3 tests/niri/window-titles.py` for sanitized classification cases.
Then check opening after moving a parent window, focus return, resizing, multiple
outputs, deliberate fullscreen, and both desktop profiles in a real session.
Static validation does not prove those behaviors or establish that draft rules
are deployed. Read-only `niri msg --json windows` and `workspaces` can help;
window dimensions alone do not establish fullscreen state. Keep private titles
out of reports and fixtures.

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
