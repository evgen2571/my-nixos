# Zen Browser

The shared profile has ChatGPT, Development, and Chill / Watch spaces. GitHub and
Google Calendar are Essentials available in every space. URL routes choose a
space for new tabs; existing tabs stay where they are. Unmatched external links
use the most recent space.

`Ctrl+backtick` toggles compact mode. Check **Settings > Keyboard Shortcuts** for
browser bindings. Niri uses `Alt+grave` to cycle windows of the same app.
For browser-to-editor problem imports, see [competitive programming](competitive-programming.md).

## Change spaces, pins and routes

[config/zen/profile.nix](../../config/zen/profile.nix) owns shared spaces, pins,
routes, keyboard shortcuts and Sine. Private configuration supplies personal
project associations and per-host profile selection.

Keep existing UUIDs when adopting a space or pin: changing an ID creates a new
item. Routes use simple URL substring matching. `spacesForce`, `pinsForce`, and
`spaceRouting.force` remain false to preserve undeclared items. Real ChatGPT
project URLs must be copied from the browser; they cannot be inferred from names.
Keep those names and URLs in private configuration. The public
[project-pin map](../../config/zen/chatgpt-projects.nix) stays empty; private host
modules can set
`my.primaryUser.home.settings.programs.zen-browser.profiles.default.spaces.ChatGPT.pins`.

The [module](../../modules/apps/zen-browser.home.nix) installs Zen when
`my.user.apps.zenBrowser.enable` is set. A null `profilePath` leaves its writable
profile unmanaged. To adopt an existing profile:

1. Open `about:profiles` and record the final directory component of its Root
   Directory. Each host can differ.
2. Close Zen and back up its entire configuration directory:

   ```sh
   cp -a ~/.config/zen ~/zen-backup-$(date +%Y%m%d-%H%M%S)
   ```

3. The shared profile contains example UUIDs. Preserve existing space/pin IDs
   through private `my.primaryUser.home.settings.programs.zen-browser.profiles.default`
   overrides, using `lib.mkForce` on each `id` leaf. Changing an ID creates a new
   browser item even when force flags are false. Set the actual
   directory name as `my.user.apps.zenBrowser.profilePath` in the host's private
   Home Manager settings.
4. Follow [deployment](../operations/deployment.md), with Zen closed during
   activation. If shortcut state does not yet exist, open Zen once to create it,
   then close it before trying again.

## Profile safety and troubleshooting

History, cookies, logins, add-ons and sessions remain writable. Do not commit or
symlink the whole profile into the Nix store. The upstream flake may skip writes
while Zen holds its profile lock.

The shortcut schema is declared as `keyboardShortcutsVersion = 21`. After a
browser update, inspect `zen.keyboard.shortcuts.version` in `about:config` if
bindings stop applying; do not infer the schema from the version comment.

Sine's engine is pinned by the flake, but configured mods are fetched from its
live store during activation. Those mods are not immutable hash-pinned builds,
and their UI preferences are not fully managed here.
