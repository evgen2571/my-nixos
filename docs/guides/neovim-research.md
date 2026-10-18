# Neovim development and research

I use this editor setup for development and Python research. Nix installs Neovim
and its Python provider; project kernels still use their own uv environments.
Home Manager copies the Lazy configuration into a writable directory while
preserving generated `lua/matugen.lua`.

## Prepare the editor

1. Build and deploy the matching host through [maintenance](maintenance.md) or,
   for my production machines, [deployment](deployment.md). Start a new shell
   afterward so it uses the installed tools.
2. Run `:Lazy restore` in Neovim to install the pinned plugins, then allow parser
   installation to finish. Run `:UpdateRemotePlugins` and restart Neovim.
3. Check `:checkhealth molten`, `:LspInfo`, and `:ConformInfo` if setup fails.
   Neovim 0.12.4 was tested; Tree-sitter uses the rewritten `main` APIs.

Noctalia owns the theme. Regenerate its palette once after deploying an updated
template, before opening Neovim. Missing or invalid generated themes use Base16
default dark. SIGUSR1 reloads the theme through one configuration watcher.
Generated files stay outside Git and activation doesn't overwrite them.

## Project setup

```sh
uv init                         # only for a new project
uv add --dev pytest ipykernel debugpy mypy
uv sync                         # also after changing branches/dependencies
nvim analysis.py
```

Use `uv add numpy pandas matplotlib ...` for project research libraries. Add
`jupyterlab` or `mlflow` to the project's development group only when needed.
Commit `pyproject.toml` and `uv.lock`. Prefer `.venv`; an absolute or project-relative
`UV_PROJECT_ENVIRONMENT` is supported. Buffer/project roots determine interpreter
selection; a local environment takes priority over an activated environment.
A uv project without an environment never silently falls back to system packages.
After creating/replacing an environment, restart its LSP clients (`:LspRestart`) and
kernel. Start Neovim inside the project shell for its other environment variables.

The Nix Python provider hosts Molten only. Project kernels, debug targets and tests
use project Python. `<leader>mi` registers a kernelspec with a stable project-specific
name and absolute interpreter path; recreate it after moving a project. Remove old
specs with `uv run jupyter kernelspec uninstall nvim-<id>`.

Ruff provides fast linting and formatting; Pyright handles completion and basic
open-file type diagnostics. Mypy is an explicit project check. Configure rule sets
in `pyproject.toml`; services such as JupyterLab and MLflow are never global installs.

## Finding keybindings (leader is Space)

Press `Space` to see a compact, borderless, bottom-aligned Which-Key menu
in multiple columns. Its maximum height is limited to 12 rows. The plugin
internally uses a floating Neovim window even for this classic presentation.
Use `Space ?` to open the menu as a persistent guide (Esc to close),
or `Space s k` to fuzzy-search all mapped keys by name. Groups include
Search, Code / build, Bookmarks, Git, Debug, Remote SSH, notebooks,
Markdown, and tests / toggles; they follow existing mappings rather than
replacing them. Remote SSH uses `Space r`; window resizing remains on Alt
+ h/j/k/l.

| Keys | Action |
| --- | --- |
| `Space ?` | Open interactive shortcut guide |
| `Space s k` | Search shortcuts by description |
| `Space s f` / `Space s g` | Find project files / grep content (local or remote) |
| `Space Space` | Switch open buffers |
| `Space b a` / `Space b m` | Bookmark current file / show Harpoon menu |
| `Space b 1` through `Space b 4` | Jump to a bookmarked file |

Previous `Space a`, `Space e`, and Alt+a/s/d/f Harpoon shortcuts still
work; they are kept as compatibility aliases. The grouped menu displays
the new `Space b` alternatives.

Telescope's pinned utilities need a small local compatibility fallback
because Neovim 0.12 lacks both the removed `vim.F.if_nil` and the newer
`vim.nonnil` (introduced in 0.13). This fallback only changes Telescope
when its own helper is missing.

## Keys (leader is Space)

| Keys | Action |
| --- | --- |
| `af`, `if`, `ac`, `ic` | Function/class Tree-sitter textobjects |
| `<leader>f` | Format selection/buffer; Ruff for Python |
| `<leader>pr`, `pt`, `pm` | Run current script, project pytest, project Mypy in terminal |
| `<leader>pj`, `pf` | Start project JupyterLab or local MLflow UI; Ctrl-C stops it |
| `<leader>tn`, `tf`, `td` | Neotest nearest, current file, debug nearest |
| `<leader>ts`, `to`, `tx` | Neotest summary, output, stop |
| `<leader>mi`, `mk` | Start this project's uv kernel, or select a registered kernel |
| `[j`, `]j`, `<leader>mc` | Previous/next `# %%` cell, execute current cell |
| `<leader>ml`, visual `<leader>me` | Execute line/selection in the current kernel |
| `<leader>mo`, `mh` | Enter output / hide floating output |
| `<leader>ms`, `mr`, `md` | Interrupt, restart, stop kernel |
| F5 / F1 / F2 / F3 / F7 | Debug continue / into / over / out / UI |
| `<leader>db`, `dB` | Breakpoint / conditional breakpoint |
| `<leader>cmd` | Debug selected CMake target |
| `<leader>ta` | Toggle automatic AI suggestions for this buffer (off initially) |
| Alt-`]` / Alt-`[` | Request or cycle AI suggestions manually |
| Ctrl-Y | Accept Blink completion when its menu is open, otherwise AI suggestion |

Wait for Molten’s kernel-ready notification before executing; early execution
produces a warning instead of losing output. Cells run in a persistent kernel; scripts run as new processes. Output appears
below cells and in Molten's output window. Kernels stop on buffer unload/editor
exit; use `md` when finished to release GPU memory. Missing kernels produce an
instruction to initialize; registration errors explain how to add `ipykernel`.

GoogleTest remains supported: build the test executable, select tests/directories
in Neotest's summary and run `:ConfigureGtest` to associate the executable. The
previous wildcard/CMake adapter options were unsupported. CMake, C/C++, Rust and
GoogleTest share Nix's `lldb-dap` (resolved to an absolute executable path); Go keeps dap-go with declarative Delve. Java,
Unity and Godot integrations retain their existing settings.

## Markdown and API documentation

Markdown works in any `.md` file; Neovim does not load an Obsidian plugin.
`render-markdown.nvim` renders headings, checkboxes, links, tables and fenced
code blocks directly in Neovim. Prose wraps at word boundaries with relative
line numbers and visible whitespace disabled only for Markdown buffers.
Markdown and Markdown-inline Tree-sitter parsers are already installed.

| Keys | Action |
| --- | --- |
| `<leader>vr` | Toggle inline Markdown rendering |
| `<leader>vp` | Show a side-by-side Markdown preview inside Neovim |
| `Alt-c` | Toggle a task checkbox |
| `<leader>f` | Format Markdown with Prettier (explicit only; no format-on-save) |
| `K` | LSP hover documentation for symbols and Markdown links |
| `gd` | Follow a Markdown reference or code symbol (with language server attached) |

Marksman provides Markdown LSP navigation, completion and reference diagnostics.
Open a Markdown file and use `:LspInfo` to check it attached. The renderer's
checkbox and callout completions are enabled through its built-in LSP source.

Pressing `K` requests LSP hover in a compact popup by the cursor (up to
60 columns and 12 lines). Hover Markdown drops decorative `---` dividers and
redundant empty lines while preserving code blocks, links and actual text.
The popup remains focusable for scrolling. If no hover-capable language server
is attached, `K` displays a short notification instead of invoking
`keywordprg` (for example, `go doc` in a terminal).
Go and gopls are installed declaratively for Go projects; open a module with
`go.mod` and check `:LspInfo` if hover is unavailable.

`:Man` provides Unix manual pages, not language API docs. For Java, keep the
existing JDTLS integration: open a Java project, check `:LspInfo`, then press
`K` on a symbol for Javadoc hover. Neovim supplies this binding when LSP is
attached; no separate `man.lua` plugin is needed. Python, Rust and other
languages use their respective language servers for hover documentation.

## Notebooks and plots

Open an `.ipynb`, then run `:NotebookPair`. This explicitly pairs it with a
`py:percent` sibling and opens the Python source. Save your edits, then run
`:NotebookSync` to synchronize with the notebook. Pairing refuses to overwrite an
existing Python sibling; synchronization refuses modified paired buffers. Keep
both files in version control. Notebook outputs, execution counts and metadata
stay in `.ipynb`; Molten outputs are session-local and are not automatically saved
into the notebook. Open it in JupyterLab to execute and persist notebook outputs.
After changing code, old stored outputs may be stale until rerun in JupyterLab.
Avoid editing both representations simultaneously. Jupytext is a small declarative
CLI dependency; there is no implicit conversion on every save.

For inline Matplotlib plots execute `%matplotlib inline` in the kernel first.
Image rendering activates only with an attached UI, Kitty graphics, ImageMagick,
and (inside tmux) `allow-passthrough on`. Reload tmux's config after deployment;
check with `tmux show-options -gv allow-passthrough`. Set
`NVIM_RESEARCH_IMAGES=0` to force text mode. Unsupported terminals/headless sessions
retain text output; save figures and open them externally or use JupyterLab.
`MoltenImagePopup` can open image output externally where a viewer is configured.
Large DataFrames, rich widgets and extensive plots are best inspected in
JupyterLab (`pj`); Molten supports small textual previews and HTML output through
`:MoltenOpenInBrowser`.

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

## Verification

`tests/neovim/run.sh` runs lightweight headless assertions with installed plugins
and parsers. Use a separate XDG config/data/state/cache tree for isolation; copy
`config/nvim` and plugin directories (not directory symlinks) into it. Use the Nix-wrapped
Neovim with its Python provider enabled when testing remote plugins. The smoke test checks
highlighting and textobject deletion, adapters, keymaps, formatter availability,
LSP settings, lint policy and AI toggling without inference. It does not download
test dependencies or start services automatically.

See [validation results](../archive/neovim-validation.md) for the runtime checks actually run
and the desktop checks still required.

## Configuration ownership

See [the ownership map](../reference/neovim-ownership.md) before changing editor behavior.
Python project, notebook commands and kernel helpers live in
`config/nvim/lua/languages/python.lua`; `custom.python` remains an alias.
The `K` binding and popup implementation live together in `integrations/hover.lua`;
LSP attachment/navigation and Telescope search keep their existing owners.
