# App configs

My desktop and editor notes are in [Umbriel](umbriel/README.md), [Niri](niri/README.md),
[Noctalia](noctalia/README.md), [Neovim](nvim/README.md), and [Zen](zen/README.md).
The [modules](../modules/README.md) enable these configs for each host.

## Terminal workflow

I use Kitty with Fish, tmux, and Neovim. In [Fish](fish/config.fish), `cd` uses
zoxide to jump to familiar directories. `l` lists files with eza, `ll` adds hidden
files, details, and Git status, and `lt` shows a two-level tree.

Atuin handles shell history, with automatic sync disabled. The
[toolchain module](../modules/dev/bundles/toolchains.home.nix) also installs `tldr`
(tealdeer) and `bat`. Fish loads direnv environments after you approve the project's
`.envrc` with `direnv allow`.

My [tmux prefix](../modules/dev/tmux/home.nix) is `Ctrl+Space`. `Ctrl+O` opens the
sesh picker without a prefix. It includes running sessions, configured sessions,
and project directories directly under `xdg.userDirs.projects` (`~/dev` on the PC),
even ones I haven't visited yet. Zoxide scores put familiar projects first.

New project sessions open `nvim .` in an `nvim` window and a second window named
`term`. Running plain `tmux` in Fish first tries to attach to an existing session;
if there isn't one, it uses sesh for the current directory. Project startup
commands live in [`sesh/sesh.toml`](sesh/sesh.toml).
