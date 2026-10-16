# Agent guide: Neovim

Use this guide **only for Neovim/editor tasks**. Begin with the narrowest matching source. The user-facing workflow is in [../neovim-research.md](../neovim-research.md); the recorded test history is in [../neovim-validation.md](../neovim-validation.md).

## Ownership and entry points

| Change | Start here | Also inspect when relevant |
| --- | --- | --- |
| Editor mappings, UI and basic behavior | `config/nvim/lua/custom/keymaps.lua`, `options.lua`, `hover.lua` | Existing plugin mappings, `config/nvim/init.lua` |
| Plugin addition or customization | `config/nvim/lua/custom/plugins/` | `config/nvim/lua/kickstart/plugins/`, `config/nvim/lazy-lock.json` |
| Telescope search or hover documentation | `config/nvim/lua/kickstart/plugins/telescope.lua`, `config/nvim/lua/custom/hover.lua` | LSP keymaps and shared floating-window logic |
| LSP, completion or formatting | `config/nvim/lua/kickstart/plugins/lsp.lua`, `completion.lua`, `conform.lua` | Matching `custom/plugins/` language configuration |
| Language-specific Python/research | `config/nvim/lua/custom/python.lua`, `custom/plugins/molten-nvim.lua` | `after/ftplugin/python.lua`, [research workflow](../neovim-research.md) |
| Install language servers or editor packages | `modules/user-dev/neovim/default.nix` | Host profiles / language bundles |
| Change how dotfiles are deployed | `modules/user-dev/neovim/config.nix` | `lib/config-paths.nix`, generated theme behavior |
| Theme integration | `config/nvim/lua/custom/theme.lua`, `config/nvim/lua/matugen-template.lua` | `config/noctalia/` and SIGUSR1 behavior |

## Invariants

- This is a Lazy/Kickstart-derived Neovim setup with local customizations. **Inspect both plugin trees before changing a shared mapping or option**; do not replace the plugin manager or start a competing configuration tree for a small task.
- The NixOS module installs the editor and provider packages. The Home Manager activation copies `config/nvim/` into the writable `~/.config/nvim` using rsync and **excludes `lua/matugen.lua`**. Do not replace this copy mechanism with a read-only symlink, or commit generated palettes.
- `config/nvim/lazy-lock.json` pins plugins. Avoid unrelated upgrades or regenerating the lockfile when adjusting UI behavior.
- Keep keybind ownership unambiguous; check existing keymaps, which-key descriptions, and plugin defaults before introducing new bindings. Do not rewrite a larger keybinding scheme for a one-window display bug.
- Python notebook kernels and virtual environments belong to each project; the Nix editor Python provider is not a substitute for project dependencies.
- A GUI hover/split/floating-window interaction may require human verification. Do not claim a headless smoke test verified its appearance.

## Minimal execution path

1. Find the exact keymap, command, plugin or filetype hook. Read its entry point and direct callers only.
2. Reproduce or characterize the failure, particularly version-specific APIs (Neovim and plugins).
3. Make the smallest change. Reuse the existing UI and styling conventions.
4. Run relevant targeted editor checks when dependencies are available. `bash tests/neovim/run.sh` is the repository smoke entry point; inspect it before relying on isolation claims. For competitive programming, see `tests/neovim/competitive.py`.
5. Report whether behavior was actually tested in a graphical Neovim session. Do not touch the user's live `~/.config/nvim` or restart the running editor without approval.

**Do not load VPN, server, or browser guides for an ordinary Neovim change.**
