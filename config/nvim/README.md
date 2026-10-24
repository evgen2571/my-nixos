# Neovim

I started with [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim) and
split the config into smaller files as I added tools for Python notebooks and
competitive programming.

## First run

The [Nix module](../../modules/dev/neovim/home.nix) installs Neovim and runtime
tools, including clipboard support, Node.js, and ImageMagick. Enable language
toolchains separately in your host profile for their servers, formatters, and
debuggers. lazy.nvim installs the plugins pinned in [`lazy-lock.json`](lazy-lock.json).

After the first plugin installation, run `:Lazy restore`. For Python notebooks,
also run `:Lazy load molten-nvim`, then `:UpdateRemotePlugins`, and restart Neovim.
Use `:checkhealth` when a provider or tool isn't working.

## Plugins

### Editing and navigation

| Plugin | What I use it for |
| --- | --- |
| [Snacks](lua/plugins/snacks.lua) | File/text search, LSP pickers, notifications, and a floating terminal. |
| [which-key](lua/plugins/editor.lua) | A shortcut menu that appears after a key prefix. |
| [mini.nvim](lua/plugins/editor.lua) | Text objects, surround editing, indent guides, and the status line. |
| [Oil](lua/plugins/oil.lua) | Editing directories like buffers, with mini.icons. Deletions don't use the trash. |
| [Harpoon 2](lua/plugins/harpoon.lua) | Per-project file bookmarks, also shown in the tab line. |
| [grug-far](lua/plugins/grug-far.lua) | Search and replace, including within a visual selection. |
| [Gitsigns](lua/plugins/gitsigns.lua), [CodeDiff](lua/plugins/codediff.lua) | Git hunks/blame, side-by-side diffs, staging, and conflict resolution. |
| [Treesitter](lua/plugins/treesitter.lua), [textobjects](lua/plugins/treesitter-textobjects.lua) | Syntax highlighting and function/class selections. |
| [nvim-autopairs](lua/plugins/autopairs.lua), [guess-indent](lua/plugins/editor.lua) | Paired brackets/quotes and indentation detection. |
| [Undotree](lua/plugins/undotree.lua), [todo-comments](lua/plugins/editor.lua) | Undo history and TODO highlighting. |
| [smart-splits](lua/plugins/smart-splits.lua), [smear-cursor](lua/plugins/smear-cursor.lua) | Moving/resizing splits and cursor animation. |

### Languages and project tools

| Plugin | What it adds here |
| --- | --- |
| [nvim-lspconfig, lazydev, Fidget](lua/plugins/lsp.lua) | Language-server setup, Neovim Lua support, and LSP progress messages. |
| [blink.cmp](lua/plugins/completion.lua) | Completion, snippets, documentation, and signature hints. |
| [Conform](lua/plugins/conform.lua), [nvim-lint](lua/plugins/linting.lua) | Formatting and optional Nix/shell linting. Format-on-save skips C, C++, and Markdown; manual formatting still works. |
| [nvim-dap](lua/plugins/debug.lua) | Debugging with DAP UI, Python/Go adapters, and LLDB setup for C/C++. |
| [Neotest](lua/plugins/neotest.lua) | pytest and GoogleTest runs, output, and debugging. |
| [cmake-tools](lua/plugins/cmake-tools.lua) | CMake generation, target selection, building, running, and debugging. |
| [rustaceanvim](lua/plugins/rust.lua) | Rust LSP, Clippy checks, runnables, tests, and LLDB debugging. |
| [nvim-java](lua/plugins/java.lua), [vim-godot](lua/plugins/godot.lua) | Java support when `JAVA_HOME` and `JDTLS_HOME` are set; Godot editor integration. |
| [Molten, image.nvim](lua/plugins/molten-nvim.lua) | Python cell execution through Jupyter kernels, with image output in supported terminals. |
| [CompetiTest](lua/plugins/competitest.lua) | Competitive Companion imports, C++ compilation, and sample tests. |
| [render-markdown, toggle-checkbox](lua/plugins/markdown.lua) | In-buffer Markdown rendering, preview, and checkbox toggling. |
| [remote-sshfs](lua/plugins/remote-sshfs.lua) | SSHFS connections and remote file/text search through Snacks. |

The default theme uses [base16-nvim](lua/plugins/base16.lua) with colors generated
by Noctalia. Without a generated palette, it falls back to `base16-default-dark`.
[Other installed themes](lua/plugins/colorschemes.lua) are Catppuccin, Kanagawa,
Rose Pine, Everforest, Lackluster, OneDark, TokyoDark, and Moonfly.

Plugins also pull in shared libraries such as Plenary, Nui, and nvim-nio.

## Keys worth knowing

`Space` is both the leader and local leader. Press it and pause for which-key,
or use `Space ?` to browse the leader menu. `Space s k` searches keybindings;
`Space f` formats the buffer, including filetypes that skip format-on-save.

LSP shortcuts use normal-mode sequences without `Space`. They need an attached
language server that supports the action.

| Keys | Action |
| --- | --- |
| `K` | Hover documentation. Press it again to enter the hover window. |
| `gd` / `gD` | Definition / declaration. |
| `gr` / `gi` | References / implementations. |
| `grt` | Type definition. |
| `grn` / `ga` | Rename / code action. `ga` also works on a visual selection. |
| `gO` / `gW` | Symbols in the current file / workspace. |

In Insert mode, `Ctrl-s` opens LSP signature help when supported. `-` opens the
parent directory in Oil. In terminal mode, `Esc Esc` returns to Normal mode
without closing the terminal.

## Python notebooks

Python tools share the project interpreter from [`languages/python.lua`](lua/languages/python.lua).
I use `uv`; run `uv sync` to create the environment before using the LSP, tests, or
debugger. For notebooks, enable the Python toolchain for Jupytext and add
`ipykernel` to the project with `uv add --dev ipykernel`.

`:NotebookPair` pairs an `.ipynb` with a `# %%` Python file; `:NotebookSync` syncs
an existing pair. Save both buffers before syncing. `Space m i` starts the project
kernel; wait for it to report ready before running cells with `Space m c`.

Image output needs Kitty graphics and ImageMagick, plus `allow-passthrough` in
tmux. Set `NVIM_RESEARCH_IMAGES=0` to turn image support off.

## Competitive programming

CompetiTest uses `~/dev/cp` and `~/dev/cp/cf-template.cpp`; change those in its
spec if your layout differs. The receiver starts when you enter that workspace.
Send problems with [Competitive Companion](https://addons.mozilla.org/en-US/firefox/addon/competitive-companion/).
`F6` compiles and runs samples for C++ files under that directory, with binaries
kept in Neovim's cache.

## Where to change things

Edit these files in the repo; rebuilds replace the installed copy.

- [`init.lua`](init.lua) loads the core config and bootstraps lazy.nvim.
- [`core/`](lua/core/) holds editor options, general keymaps, autocmds, and health checks.
- [`plugins/`](lua/plugins/) holds lazy.nvim specs, including language plugins such
  as `java.lua` and `godot.lua`. Each spec keeps its settings and shortcuts together;
  [`plugins/init.lua`](lua/plugins/init.lua) lists the active specs.
- [`languages/`](lua/languages/) holds helpers shared by plugins. The Python helper
  is used by the LSP, debugger, tests, and notebooks.
- [`after/ftplugin/`](after/ftplugin/) holds Python buffer mappings.
- [`integrations/`](lua/integrations/) connects the generated theme, hover UI, and
  Harpoon bookmarks to the rest of the config.

For theme changes, edit [`matugen-template.lua`](lua/matugen-template.lua).
`lua/matugen.lua` is generated and stays writable on the machine. Existing
`harpoon.json` files are preserved for import into Harpoon 2.
