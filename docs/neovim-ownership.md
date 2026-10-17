# Neovim configuration ownership

This map describes declarative source under `config/nvim/`. `init.lua` remains
the ordered startup entry point: leaders → options → keymaps (including hover
setup) → Python command registration → autocmds → Lazy bootstrap → `plugins/init.lua`. Python
command registration loads only local Lua helpers; provider, kernel, terminal and
project operations still happen on demand. Plugin identities, settings and evaluation order are preserved.

## Before and after

Paths below are relative to `config/nvim/lua/` unless stated otherwise.

| Responsibility | Before | After / edit entry point |
| --- | --- | --- |
| Core options and autocmds | `custom/options.lua`, `custom/autocmds.lua` | `core/options.lua`, `core/autocmds.lua`; global editor behavior |
| Core keymaps and diagnostics shortcuts | `custom/keymaps.lua` also registered notebook commands and `K` | `core/keymaps.lua`; delegates hover registration |
| Hover documentation | Binding in keymaps, rendering in `custom/hover.lua` | `integrations/hover.lua`; binding, dimensions, focus and response handling |
| LSP registration and attachment | `kickstart/plugins/lsp.lua` | `plugins/lsp.lua`; server settings, buffer-local navigation, highlights and inlay hints |
| Telescope/navigation | `kickstart/plugins/telescope.lua` | `plugins/telescope.lua`; search/remote dispatch and compatibility fallback; LSP pickers stay in LspAttach |
| Completion and shortcut discovery | `kickstart/plugins/completion.lua`, `editor.lua` | `plugins/completion.lua`, `plugins/editor.lua`; Blink and which-key respectively |
| Diagnostic display / lint | LSP module / `custom/plugins/linting.lua` | `plugins/lsp.lua` / `plugins/linting.lua`; presentation versus lint producers |
| Formatting | `kickstart/plugins/conform.lua` | `plugins/conform.lua`; formatter selection, save policy and mapping |
| Debugging / tests | `kickstart/plugins/debug.lua`, `custom/plugins/neotest.lua`, `cmake-tools.lua`, `competitest.lua` | `plugins/debug.lua`, `plugins/neotest.lua`, `plugins/cmake-tools.lua`, `plugins/competitest.lua` |
| Python projects | `custom/python.lua`, consumers in LSP/DAP/tests/Molten and `after/ftplugin/python.lua` | `languages/python.lua`; shared project/interpreter/kernel owner; `custom.python` remains a startup alias |
| Notebook commands | `custom/keymaps.lua` | `languages/python.lua`; registers `NotebookPair` and `NotebookSync` from startup in every buffer |
| Notebook plugin / Python filetype | `custom/plugins/molten-nvim.lua`, `after/ftplugin/python.lua` | `plugins/molten-nvim.lua`, `after/ftplugin/python.lua`; lifecycle/keys versus buffer-local cell/run keys |
| Other languages | LSP server table plus `custom/plugins/{rust,java,godot,unity,cmake-tools}.lua` | `plugins/lsp.lua` plus `plugins/{rust,java,godot,unity,cmake-tools}.lua`; existing registration boundaries |
| Markdown | `custom/plugins/markdown.lua`, Markdown FileType hook in `custom/autocmds.lua`, Marksman in LSP, Prettier in Conform | `plugins/markdown.lua`, `core/autocmds.lua`, `plugins/lsp.lua` (Marksman), `plugins/conform.lua` (Prettier) |
| Tree-sitter | `kickstart/plugins/treesitter.lua`, `custom/plugins/treesitter-textobjects.lua` | `plugins/treesitter.lua`, `plugins/treesitter-textobjects.lua`; parser lifecycle versus textobject mappings |
| Terminals / remote integrations | `custom/plugins/nvterm.lua`, `remote-sshfs.lua`, Telescope dispatch | `plugins/nvterm.lua`, `plugins/remote-sshfs.lua`, `plugins/telescope.lua`; lifecycle versus picker dispatch |
| Theme | `custom/theme.lua`, `custom/plugins/base16.lua`, `colorschemes.lua`, `matugen-template.lua` | `integrations/theme.lua`, `plugins/base16.lua`, `plugins/colorschemes.lua`, `matugen-template.lua`; existing fallback/SIGUSR1 lifecycle |
| Editor/provider tooling and writable deployment | `modules/user-dev/neovim/{default,config}.nix` (repository paths) | Unchanged; Nix provider packages remain separate from uv project environments/kernels; activation preserves generated `lua/matugen.lua` |

## Migration and deferred work

The source tree now has one responsibility-based layout:

```text
lua/
├── core/          # options, core mappings/autocmds and :checkhealth core
├── plugins/       # all active Lazy specs; init.lua owns registration order
├── languages/     # shared Python project/interpreter/kernel helpers and commands
├── integrations/  # hover UI and Noctalia/Matugen theme lifecycle
├── optional/      # inactive neo-tree spec; deliberately outside the registry
└── matugen-template.lua  # source template; generated matugen.lua stays here too
```

`plugins/init.lua` preserves the previous explicit base spec order, followed by
individual imports in the former custom-plugin directory's alphabetical order.
Do not replace this with a directory-wide import without checking ordering.
The empty which-key and guess-indent placeholder files were removed; both actual
declarations remain in `plugins/editor.lua`. The inactive neo-tree spec remains
available under `optional/` and is not activated by this migration.

`custom.python` remains a startup-registered compatibility require returning the
same `languages.python` module table, without retaining a legacy directory.
All repository callers use the canonical language path. Keybinding and command
aliases are unchanged. Health reporting is now `:checkhealth core`.

Deferred: splitting the LSP server table by language, moving every filetype hook,
and redesigning plugin defaults or mappings. Distinct lifecycle boundaries remain
intentional, including dedicated Rust/Java plugins and shared LSP registration.
No plugin was added or upgraded, and no Nix deployment mechanism changed.

## Validation boundaries

Use `tests/neovim/run.sh` only with disposable XDG config/data/cache/state roots
and a copy of the installed plugins. `tests/neovim/competitive.py` also opens a
localhost receiver on port 27121 and reads the existing C++ template; isolate
its editor paths and confirm that port is free before running it.

Headless checks cannot establish popup appearance, interactive notebook plots,
remote SSH behavior or visual Matugen signal reload. Record fresh results and
manual checks in the PR; the historical validation guide is not evidence for a
new run. No Nix build is required for this Lua/documentation-only migration.
