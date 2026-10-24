# Niri

I use Niri's scrolling layout with mostly keyboard navigation. Noctalia handles the panels, launcher, clipboard, wallpaper picker, and lock screen.

Most of my movement is on HJKL:

| Shortcut | What it does |
| --- | --- |
| `Mod+H/L` | Left/right column, then the next monitor at the edge |
| `Mod+J/K` | Up/down window, then workspace at the edge |
| `Mod+Shift+H/J/K/L` | Move a column or window |
| `Mod+Alt+H/J/K/L` | Resize |
| `Mod+Return` | Kitty |
| `Mod+Shift+Return` | Dropdown terminal with a persistent tmux session |
| `Mod+Space` / `Mod+S` | Launcher / control center |
| `Mod+Comma` | Noctalia settings |
| `Mod+Shift+P` | Lock and suspend |
| `Mod+Shift+D` | Draw on the screen with Wayscriber |

The full list is in [`sub/binds.kdl`](sub/binds.kdl). I change keys there, layout in [`sub/layout.kdl`](sub/layout.kdl), and window behavior in [`sub/rules/`](sub/rules/).

I select the workspace layout with `my.user.desktop.niriConfig.workspaceProfile`:
`pc`, `laptop`, or `default`. The PC splits workspaces across `DP-1` and `HDMI-A-1`;
the laptop uses `eDP-1`. Adjust the names and modes in
[`sub/outputs.kdl`](sub/outputs.kdl) and the workspace files for your monitors.

Games matched by the window rules open fullscreen on `gaming`, the third workspace
on the PC's HDMI output and the fifth on the laptop. Add a rule for games with
other app IDs; launching through Steam or Prism doesn't match them automatically.

Noctalia generates `noctalia*.kdl` files in the live config directory. Keep those
out of Git; see [Noctalia](../noctalia/README.md) for theme settings.
