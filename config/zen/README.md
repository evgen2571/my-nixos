# Zen

Nix installs Zen and applies a few shared browser defaults, the compact-mode shortcut (Ctrl + backtick), and Sine integration.

The managed profile restores the previous session on startup and keeps pinned tabs
on their last visited pages instead of resetting them to their pinned URLs.
Closing a pinned tab unloads it and switches tabs without resetting its page.

My **spaces, pins, routes, and workspace IDs are personal**, so they belong in `my-nixos-private`, not in this directory. I don't ship a copy of my browser layout.

`my.user.apps.zenBrowser.profilePath` selects an existing profile directory. Leave it `null` if you don't want Nix to manage a browser profile. You can find the directory in `about:profiles`.

If you adopt an existing profile, close Zen and back up `~/.config/zen` first. Keep your existing space and pin UUIDs: making up new ones creates new browser items. Sessions, passwords, extensions, and history stay browser-owned and writable.

Close Zen before applying layout changes. Home Manager skips spaces, Essentials,
pins, and routes while the browser is running; closing or restarting Zen afterward
doesn't apply the skipped changes. Rerun your host's `just switch-*` command with
the private input selected while Zen is closed.

The upstream Home Manager module reapplies declared pin URLs during activation.
After a rebuild with Zen closed, declared pins can therefore return to those URLs;
ordinary browser restarts use the saved session.
