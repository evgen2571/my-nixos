# Kitty and project terminals

In Niri, `Mod+Return` opens Kitty, `Mod+Shift+Return` toggles the dropdown terminal,
and `Mod+C` opens the project-session picker. Inside tmux, `Ctrl-O` opens the sesh
picker; `sesh connect cp` enters the [competitive-programming](competitive-programming.md)
workspace.

| Keys in Kitty | Action |
| --- | --- |
| `Super+C` / `Super+V` | Copy / paste clipboard |
| `Shift+Insert` | Paste primary selection |
| `Ctrl+Shift+Enter` | New terminal window within Kitty |
| `Ctrl+Shift+T` / `Ctrl+Shift+Q` | New tab / close tab |
| `Ctrl+Shift+Left/Right` | Previous/next tab |
| `Ctrl+Shift+H` | Scrollback in `less` |
| `Ctrl+Shift+K/J` | Scroll up/down a line |
| `Ctrl+Shift+Up/Down` | Increase/decrease font size |
| `Ctrl+Shift+Backspace` | Restore font size |

Desktop bindings can intercept keys before Kitty sees them. The final font-size
bindings override earlier scroll bindings for the same Up/Down combinations.

## Configuration and graphics

Edit [kitty.conf](../../config/kitty/kitty.conf) for terminal behavior. The
[Kitty module](../../modules/dev/kitty.home.nix) installs it through
[config-paths.nix](../../lib/config-paths.nix), including the host's
`my.user.dev.kitty.fontSize`. Colors come from the included Noctalia theme.

Project session behavior belongs to [config/sesh](../../config/sesh), shell
behavior to [config/fish](../../config/fish), and multiplexing to
[tmux module](../../modules/dev/tmux/home.nix). Keep a terminal change in its owning layer.

[Neovim plots](neovim.md#python-projects-and-notebooks) need Kitty graphics and,
inside tmux, `allow-passthrough on`. Check `tmux show-options -gv allow-passthrough`
after reloading tmux configuration. Real plot rendering through both paths still
needs desktop verification; text output remains available.
