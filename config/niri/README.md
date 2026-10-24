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

Games matching `steam_app_<number>`, `gamescope`, `cs2`, `Minecraft`, `minecraft` or `osu!` open fullscreen on `gaming`: third on the PC's HDMI output, fifth on the laptop. Steam and Prism launcher windows stay maximized. Games with other app IDs need an explicit match; launching through Steam or Prism alone does not identify them to Niri.

Zen login popups follow the normal browser rules. Their login title can arrive after opening, so title-based floating opening rules are unreliable.

Orca's maximized `code` rule covers only the observed `Orca` title. Krita keeps its native tiling/dialog behavior: its observed main and auxiliary windows both report `krita` / `Krita`. Niri's `is-floating` matcher applies after opening, so it cannot safely select which one to maximize initially.

A short real desktop clip will go here once I have one worth showing.
