# KDE Plasma workflow

The Plasma session on `nixos-pc` is configured to use the same keyboard repeat
as Niri (250 ms delay, 35 repeats/sec) and focus the window under the pointer
without automatically raising it.

## Tiling

Plasma has a built-in tiling editor. Press `Meta+T`, create a layout, then drag
windows to its zones. Windows can also be tiled with the standard quick-tile
shortcuts:

- `Meta+Left` / `Meta+Right` — left or right half
- `Meta+Up` / `Meta+Down` — maximize or restore
- `Meta+Shift+Left` / `Meta+Shift+Right` — move to the adjacent screen

For a keyboard-driven workflow, assign shortcuts in **System Settings →
Shortcuts** for "Quick Tile Window to …", "Move Window to …", and "Switch to
Desktop …". Plasma’s built-in tiling is manual rather than automatic: it will
not rearrange unrelated windows the way Niri does.

## Unity and Neovim

Unity completion depends on the generated `*.sln` and `*.csproj` files. In
**Edit → Preferences → External Tools**, enable generation for embedded,
local, registry, Git, and built-in packages, then use **Regenerate project
files** once. The Neovim OmniSharp client will use those files and load all
Unity assembly projects.

Saving from Neovim does not require Unity to be the active window. Unity does,
however, refresh its Asset Database when it regains focus if Auto Refresh is
enabled; enable it in **Edit → Preferences → Asset Pipeline**. This repository
also installs `apyra/nvim-unity-sync` in Neovim: `:Usync` rebuilds the compile
entries in `Assembly-CSharp.csproj`, and Neo-tree create/delete/rename/move
operations trigger it automatically. Newly created or renamed scripts may
still require Unity to regain focus or `Assets → Refresh` because Unity owns
its Asset Database.

Install the Unity-side package separately in every Unity project through
**Package Manager → Add package from git URL**:

```
https://github.com/apyra/nvim-unity.git
```

Then select **Neovim Code Editor** under **Edit → Preferences → External Tools**
and regenerate project files once. After Unity regenerates project files, run
`:LspRestart omnisharp` in Neovim if completions do not update immediately.
