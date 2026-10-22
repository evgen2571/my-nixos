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

PC and laptop use different workspace layouts. Don't reuse my monitor names blindly. Noctalia also generates some Niri files at runtime, so not everything in the live config belongs in Git.

A short real desktop clip will go here once I have one worth showing.
