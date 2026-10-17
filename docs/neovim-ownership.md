# Neovim configuration ownership

This map describes declarative source under `config/nvim/`. `init.lua` remains
the ordered startup entry point: leaders → options → keymaps (including hover
setup) → Python command registration → autocmds → Lazy bootstrap/specs. Python
command registration loads only local Lua helpers; provider, kernel, terminal and
project operations still happen on demand. Plugin specs and their order are unchanged.

## Before and after

Paths below are relative to `config/nvim/lua/` unless stated otherwise.

| Responsibility | Before | After / edit entry point |
| --- | --- | --- |
| Core options and autocmds | `custom/options.lua`, `custom/autocmds.lua` | Unchanged; global editor behavior |
| Core keymaps and diagnostics shortcuts | `custom/keymaps.lua` also registered notebook commands and `K` | `custom/keymaps.lua` owns editor mappings; delegates hover registration |
| Hover documentation | Binding in keymaps, rendering in `custom/hover.lua` | `custom/hover.lua` owns binding, dimensions, focus and response handling |
| LSP registration and attachment | `kickstart/plugins/lsp.lua` | Unchanged; server settings, buffer-local navigation mappings, highlights and inlay hints |
| Telescope/navigation | `kickstart/plugins/telescope.lua` | Unchanged; search mappings, remote/local dispatch and compatibility fallback; LSP pickers remain in LspAttach |
| Completion and shortcut discovery | `kickstart/plugins/completion.lua`, `editor.lua` | Unchanged; Blink and which-key configuration respectively |
| Diagnostic display / lint | LSP module / `custom/plugins/linting.lua` | Unchanged; diagnostic presentation versus lint producers are distinct |
| Formatting | `kickstart/plugins/conform.lua` | Unchanged; formatter selection, save policy and format mapping |
| Debugging / tests | `kickstart/plugins/debug.lua`, `custom/plugins/neotest.lua`, `cmake-tools.lua`, `competitest.lua` | Unchanged; adapters and workflows consume the shared Python resolver |
| Python projects | `custom/python.lua`, consumers in LSP/DAP/tests/Molten and `after/ftplugin/python.lua` | `custom/languages/python.lua` is the shared project/interpreter/kernel helper; consumers use this path; `custom/python.lua` forwards for compatibility |
| Notebook commands | `custom/keymaps.lua` | `custom/languages/python.lua` registers `NotebookPair` and `NotebookSync` from startup; available outside Python buffers |
| Notebook plugin / Python filetype | `custom/plugins/molten-nvim.lua`, `after/ftplugin/python.lua` | Unchanged; plugin lifecycle/keys versus buffer-local cell/run keys |
| Other languages | LSP server table plus `custom/plugins/{rust,java,godot,unity,cmake-tools}.lua` | Unchanged; common LSP registration versus dedicated language plugin behavior |
| Markdown | `custom/plugins/markdown.lua`, Markdown FileType hook in `custom/autocmds.lua`, Marksman in LSP, Prettier in Conform | Unchanged; rendering/view commands, local reading options, language server and formatter respectively |
| Tree-sitter | `kickstart/plugins/treesitter.lua`, `custom/plugins/treesitter-textobjects.lua` | Unchanged; parser/highlight lifecycle versus textobject mappings |
| Terminals / remote integrations | `custom/plugins/nvterm.lua`, `remote-sshfs.lua`, Telescope dispatch | Unchanged; terminal lifecycle, remote connection lifecycle and picker selection |
| Theme | `custom/theme.lua`, `custom/plugins/base16.lua`, `colorschemes.lua`, `matugen-template.lua` | Unchanged; generated palette/fallback and SIGUSR1 watcher remain owned by `custom/theme.lua` |
| Editor/provider tooling and writable deployment | `modules/user-dev/neovim/{default,config}.nix` (repository paths) | Unchanged; Nix provider packages remain separate from uv project environments/kernels; activation preserves generated `lua/matugen.lua` |

## Bounded migration and deferred work

The concrete confusion was notebook command registration in a general keymap
file, and a hover binding separated from its implementation. Both now have
feature owners. The Python helper moved once to a language entry point; the old
require path returns the same module table, preserving existing integrations and
kernel readiness state. No plugin was added, removed, renamed or upgraded.

The two plugin trees are retained: `init.lua` explicitly orders Kickstart specs
and Lazy imports `custom.plugins`. Empty legacy `custom/plugins/which-key.lua`
and `guess-indent.lua` return no specs; the actual declarations live in
`kickstart/plugins/editor.lua`. `kickstart/plugins/neo-tree.lua` is not imported.
These are confusing names, but not competing active plugin declarations.

Deferred: wholesale `core/`, `plugins/` and `integrations/` moves; splitting the
LSP server table into one file per language; moving every filetype hook; changing
plugin defaults or mappings. Those changes add loading/ordering risk without a
second active owner to eliminate. The current distinct lifecycle boundaries are
intentional, including Rust/Java dedicated LSP plugins and shared LSP registration.

## Validation boundaries

Use `tests/neovim/run.sh` only with disposable XDG config/data/cache/state roots
and a copy of the installed plugins. `tests/neovim/competitive.py` also opens a
localhost receiver on port 27121 and reads the existing C++ template; isolate
its editor paths and confirm that port is free before running it.

Headless checks cannot establish popup appearance, interactive notebook plots,
remote SSH behavior or visual Matugen signal reload. Record fresh results and
manual checks in the PR; the historical validation guide is not evidence for a
new run. No Nix build is required for this Lua/documentation-only migration.
