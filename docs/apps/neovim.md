# Neovim

Start `nvim` inside your project. Space is the leader key: press it to discover
shortcuts, `Space ?` to keep the guide open, or `Space s k` to search bindings.

| Keys | Action |
| --- | --- |
| `Space s f` / `Space s g` | Find files / search content, including connected remote projects |
| `Space Space` | Switch open buffers |
| `Space b a` / `Space b m` | Bookmark a file / open bookmarks |
| `Space b 1` through `Space b 4` | Jump to a bookmark |
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
Check with `tmux show-options -gv allow-passthrough` after reloading its config.
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

Ctrl-Y accepts the selected Blink completion.

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
| Provider packages and installation | [Neovim module](../../modules/user-dev/neovim) |

Activation copies source into writable `~/.config/nvim` with `rsync --delete`,
except generated `lua/matugen.lua`. Keep lasting edits in this repository;
other local configuration files can be removed on the next activation. Preserve
the generated palette and the explicit plugin order. `lua/optional` contains an
inactive Neo-tree spec.

## Checks and remaining desktop verification

Inspect [tests/neovim/run.sh](../../tests/neovim/run.sh) before running it. Use
separate XDG config, data, cache and state directories, with copies of the source
and installed plugins. It does not install missing dependencies. Headless tests
cannot verify popup appearance, remote SSH sessions, or terminal graphics.

Desktop checks still needed include plots directly in Kitty and through tmux,
visual-selection execution, output focus, Ctrl-Y completion acceptance,
and real Noctalia palette reload on both desktops. Real CMake/Rust debugging,
GoogleTest execution, Go/Java/Unity/Godot runtime sessions and project
JupyterLab/MLflow widgets also need their own checks. Scientific wheel libraries
remain a project/dev-shell concern; there is no global ML environment.
