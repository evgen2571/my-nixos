# Neovim

This is my everyday editor, not a minimal config. I use it for regular development, Python notebooks, and competitive programming.

Press `Space` for the leader menu. A few shortcuts I use constantly:

| Keys | Action |
| --- | --- |
| `Space s f` / `Space s g` | Files / grep |
| `Space Space` | Switch buffers |
| `Space a` / `Space e` | Bookmark file / see bookmarks |
| `Alt-i` | Floating terminal |
| `Space g g` | Lazygit |
| `gd` / `K` | Definition / documentation |
| `Space f` | Format |
| `F5` | Debug continue |
| `F6` | Compile and run competitive-programming test cases |

The Lua files are split into [core](lua/core/), [plugins](lua/plugins/), [languages](lua/languages/), and [integrations](lua/integrations/). Edit those rather than generated theme files.

After first setup, run `:Lazy restore` and `:UpdateRemotePlugins`, then restart. The theme comes from Noctalia. Python project environments are separate; I use `uv` rather than one global Python environment.

For contests, my sesh `cp` session opens Neovim and a receiver for [Competitive Companion](https://addons.mozilla.org/en-US/firefox/addon/competitive-companion/). `Space c p i` imports a problem, and `F6` runs its tests. I keep the local template in `~/dev/cp`.

I'll add a short clip here showing search, LSP, terminal, and tests. The keybindings and plugin sources above are the up-to-date reference in the meantime.
