# Zen

I keep shared browser defaults in [`profile.nix`](profile.nix), including Sine
integration and Ctrl + backtick for compact mode.

The managed profile restores the previous session and keeps pinned tabs on their
last visited pages. Closing a pin unloads it and switches tabs without resetting
the page.

My workspaces, Essentials, pins, routes, and their IDs live in the
[private repository](../../docs/secrets.md).

Set `my.user.apps.zenBrowser.profilePath` to an existing profile directory name
from `about:profiles`, relative to `~/.config/zen`. Leaving it `null` installs Zen
without managing a profile.

Before managing an existing profile, close Zen and back up `~/.config/zen`.
Keep existing workspace and pin UUIDs to avoid creating duplicate items.
Sessions, passwords, extensions, and history stay writable and belong to Zen.

Close Zen before applying layout changes. If it's running, spaces, Essentials,
pins, and routes are skipped. Close it and rerun `just switch <host>` with your
private input selected to apply them.

A rebuild with Zen closed can reset managed pins to their declared URLs.
Ordinary browser restarts use the saved session.
