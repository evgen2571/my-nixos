# Neovim

Start `nvim` inside your project. Space is the leader key: press it to discover
shortcuts, `Space ?` to keep the guide open, or `Space s k` to search bindings.

| Keys | Action |
| --- | --- |
| `Space s f` / `Space s g` | Find files / search content, including connected remote projects |
| `Space Space` | Switch open buffers |
| `Space a` / `Space e` | Bookmark a file / open bookmarks |
| `Space b 1` through `Space b 4` / `Alt-a/s/d/f` | Jump to a bookmark |
| `Alt-i` | Toggle the persistent centered floating shell |
| `Space g g` / `Space g l` | Lazygit / Git log |
| `Space s N` | Notification history |
| `K` / `gd` | Language-server documentation / definition |
| `Space f` | Format buffer or selection |
| `Space d f` / `Space d q` | Diagnostic popup / location list |
| `Alt-\` / `Alt-x` | Vertical split / close window |
| `Alt-h/j/k/l` | Resize window |
| `Esc Esc` in a terminal | Return to normal mode |
| F5 / F1 / F2 / F3 / F7 | Debug continue / step into / over / out / toggle UI |
| `Space d b` / `Space d B` | Breakpoint / conditional breakpoint |

For contest imports and F6 testcase runs, see [competitive programming](competitive-programming.md).

## First start after deployment

Run `:Lazy restore`, wait for parser installation, then run
`:UpdateRemotePlugins` and restart Neovim. The Nix package supplies the Python
provider; project Python environments remain separate. Useful diagnostics are
`:checkhealth core`, `:checkhealth molten`, `:LspInfo`, and `:ConformInfo`.

[Noctalia](noctalia.md) generates the palette. Regenerate it after changing the
Matugen template. A missing or malformed palette falls back to Base16 default
dark; `SIGUSR1` reloads the generated colors.

## Python projects and notebooks

For a new project:

```sh
uv init
uv add --dev pytest ipykernel debugpy mypy
uv sync
nvim analysis.py
```

Add libraries such as NumPy or Matplotlib to the project. Commit `pyproject.toml`
and `uv.lock`. Use `uv sync` after dependency or branch changes. A local `.venv`
takes priority over an activated environment; `UV_PROJECT_ENVIRONMENT` may be an
absolute or project-relative path. A uv project without an environment does not
silently use system packages. Restart LSP clients and kernels after replacing an
environment. Start Neovim from the project shell to inherit its other variables.

Ruff handles linting and formatting; Pyright supplies completion and basic
open-file type diagnostics. Mypy is an explicit check.

| Keys | Action |
| --- | --- |
| `Space p r` / `Space p t` / `Space p m` | Run script / pytest / Mypy |
| `Space p j` / `Space p f` | Start project JupyterLab / MLflow; Ctrl-C stops it |
| `Space t n` / `Space t f` / `Space t d` | Test nearest / file / debug nearest |
| `Space t s` / `Space t o` / `Space t x` | Test summary / output / stop |
| `Space m i` / `Space m k` | Start project uv kernel / choose registered kernel |
| `[j` / `]j` / `Space m c` | Previous cell / next cell / execute cell |
| `Space m l` / visual `Space m e` | Execute line / selection |
| `Space m o` / `Space m h` | Enter output / hide output |
| `Space m s` / `Space m r` / `Space m d` | Interrupt / restart / stop kernel |

Wait for the kernel-ready notification before execution. Cells share kernel
state; scripts start fresh processes. Stop unused kernels to release GPU memory.
`Space m i` registers an absolute project interpreter path: recreate the
kernelspec after moving the project. Remove stale entries with
`uv run jupyter kernelspec uninstall nvim-<id>`.

Open an `.ipynb` and run `:NotebookPair` to create and open its `py:percent`
sibling. Save edits, then run `:NotebookSync`. Pairing refuses to overwrite an
existing Python sibling; syncing refuses modified paired buffers. Keep both
files in version control and avoid editing both at once. Notebook metadata,
execution counts and stored outputs remain in `.ipynb`. Molten output is
session-local; execute in JupyterLab to persist notebook outputs.

For plots, execute `%matplotlib inline` first. Inline images require an attached
UI, Kitty graphics, ImageMagick, and tmux `allow-passthrough on` when using tmux.
The existing tmux module enables passthrough and focus events. Check the effective
pane option with `tmux show -Apv allow-passthrough` and the attached terminal with
`tmux display-message -p '#{client_termname}'` (expected `xterm-kitty`). Detection
also accepts `TERM_PROGRAM=kitty` and inherited `KITTY_WINDOW_ID`; it does not rely
on `TERM` remaining `xterm-kitty` inside tmux. A missing UI, Kitty terminal,
ImageMagick `magick`, or passthrough produces a specific reason (visible sessions
receive a warning). Image setup completes before Molten's first command snapshots
its provider. After fixing a failed graphics setup, restart Neovim before
initializing another kernel. Image dimensions follow window limits, overlapping
floats clear images, and only the active tmux window displays them. Molten
reserves virtual lines behind floating output, so source text does not show
through plots with a transparent theme.
`NVIM_RESEARCH_IMAGES=0` forces text mode. Use JupyterLab for rich widgets and large
DataFrames; `:MoltenOpenInBrowser` can show HTML output.

## Markdown and other languages

Markdown rendering works without an Obsidian plugin. `Space v r` toggles inline
rendering, `Space v p` opens a side-by-side preview, and `Alt-c` toggles a task
checkbox. `Space f` runs Prettier explicitly; Markdown has no format-on-save.
Marksman supplies navigation and link diagnostics. `K` requires a hover-capable
language server; `:Man` opens Unix manual pages.

C/C++, CMake and Rust use LLDB. `Space c m d` debugs a selected CMake target.
For GoogleTest, build an executable and associate it with `:ConfigureGtest`.
Unity setup is described below.

Ctrl-Y accepts the selected Blink completion. Tab and Shift-Tab navigate native
`vim.snippet` placeholders; LSP snippets and automatic completion documentation
remain enabled. There are no custom LuaSnip snippets. Blink's Rust matcher was
evaluated: it needs a library built for the locked plugin revision. The Lua matcher
remains selected and binary downloads are disabled, so startup needs no downloaded
native binary. A future Rust migration should package the plugin and matcher
together through Nix.

Search uses Snacks Picker, including previews and `vim.ui.select`. `Space s s`
lists pickers, `Space s r` resumes, `Space s c` previews colorschemes, `Space /`
searches the current buffer, and `Space s /` greps open buffers. LSP navigation
keeps `gd`, `gr`, `gi`, `grt`, `gO`, and `gW`. SSHFS explicitly uses its Snacks
backend: `Space r c/r d/r e` connect, disconnect, and edit SSH configuration;
the `RemoteSSHFS*` commands remain available. Connected file/text searches use
the SSHFS backend; disconnected searches use local Snacks pickers.

Harpoon 2 stores marks by working directory. `Space a` adds a file and `Space e`
opens its editable menu; `Space b a`, `Space b m`, and `Space b e` are removed.
On first use in a project with no Harpoon 2 data, old marks from
`stdpath('data')/harpoon.json` and `stdpath('config')/harpoon.json` are imported.
Existing Harpoon 2 data takes precedence. Old files are preserved. The tabline
uses the existing `Harpoon*` theme groups; Harpoon 2 has no built-in tabline API.

`K` uses native LSP hover with a rounded border and screen-relative size limits
(85% width, 65% height). Long lines wrap, including long identifiers, and Markdown
is passed through without custom trimming. Press `K` again to focus the popup,
then use Ctrl-F/Ctrl-B or Ctrl-D/Ctrl-U to scroll and `q` to close; Ctrl-W p returns
to the source. Reopen after resizing to calculate fresh limits. Which-Key keeps
its compact classic layout with plain text group names and no mapping icons.

## Unity projects

Install this package separately in each Unity project through **Package Manager >
Add package from git URL**:

```text
https://github.com/apyra/nvim-unity.git
```

Select **Neovim Code Editor** in **Edit > Preferences > External Tools**. Enable
project generation for embedded, local, registry, Git and built-in packages,
then regenerate project files. OmniSharp needs the generated `.sln` and
`.csproj` files. Run `:LspRestart omnisharp` if completion stays stale.

Enable Unity's **Auto Refresh** under **Preferences > Asset Pipeline**. Unity
refreshes its Asset Database when it regains focus. In Neovim, `:Usync` rebuilds
compile entries in `Assembly-CSharp.csproj`; Neo-tree file operations trigger it
when that optional file tree is active. Newly created or renamed scripts may
still need Unity focus or **Assets > Refresh**. Unity runtime integration needs
a check in a real project.

## Changing the configuration

| Change | Source |
| --- | --- |
| Options, mappings, autocmds | [lua/core](../../config/nvim/lua/core) |
| Plugins and explicit loading order | [lua/plugins](../../config/nvim/lua/plugins) |
| Python environment and notebook commands | [languages/python.lua](../../config/nvim/lua/languages/python.lua) |
| Hover and theme lifecycle | [lua/integrations](../../config/nvim/lua/integrations) |
| Provider packages and installation | [Neovim module](../../modules/dev/neovim) |

Activation copies source into writable `~/.config/nvim` with `rsync --delete`,
except generated `lua/matugen.lua` and legacy `harpoon.json` marks. Keep lasting edits in this repository;
other local configuration files can be removed on the next activation. Preserve
the generated palette, legacy marks, and the explicit plugin order. `lua/optional` contains an
inactive Neo-tree spec.

## Checks and remaining desktop verification

Inspect [tests/neovim/run.sh](../../tests/neovim/run.sh) before running it. Use
separate XDG config, data, cache and state directories, with copies of the source
and installed plugins. It does not install missing dependencies. Headless tests
cannot verify popup appearance, remote SSH sessions, or terminal graphics.

The graphics acceptance check is a real Matplotlib PNG (`%matplotlib inline`,
`import matplotlib.pyplot as plt; plt.plot([1, 2, 3]); plt.show()`) through Molten
in Kitty, repeated inside tmux. Scroll, resize, enter/hide/close output, and repeat
with `NVIM_RESEARCH_IMAGES=0` for text fallback. Headless capability simulations
are not evidence of displayed pixels.

Validation for this migration passed the 16 isolated smoke checks, native hovers
from Pyright/gopls/clangd with long signatures and Markdown, Snacks file/grep
pickers, notification history, persistent floating terminal, native snippet
expansion/navigation, and SIGUSR1 theme reload/fallback. Real Matplotlib PNGs were
visually checked in Kitty directly and in a separate tmux server (including
without inherited Kitty variables). Output focus/scroll/close, hide/reopen,
source scrolling, and window resize passed in both. Explicit image-disabled
text output was checked separately. `nix flake check --no-build` evaluated all
three hosts; the `module-style` and `config-paths` Nix checks were built.

Remaining desktop checks include a real SSHFS connection and remote preview,
visual-selection execution, Ctrl-Y completion acceptance,
and real Noctalia palette generation/reload on both desktops. Real CMake/Rust debugging,
GoogleTest execution, Go/Java/Unity/Godot runtime sessions and project
JupyterLab/MLflow widgets also need their own checks. Scientific wheel libraries
remain a project/dev-shell concern; there is no global ML environment.
