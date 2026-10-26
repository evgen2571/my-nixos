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

## Selected websites through the VPN

PC and laptop expose a SOCKS5 proxy at `127.0.0.1:1080` through the existing
client VPN namespace. Other hosts leave `my.system.services.browserVpnProxy`
disabled. The host socket stays on loopback; `systemd-socket-proxyd` connects
to microsocks inside the namespace, using its resolver and kill switch.

Enable `my.user.apps.zenBrowser.vpnProxy.enable` with an existing `profilePath`.
Its `domains` list takes bare lowercase domains, including their subdomains.
My list lives in private `hosts/desktop.nix`, shared by PC and laptop; it is
guarded so private main still works with public main before this module lands.
Rebuild from this repository and restart Zen after changing the list.
When disabling it, reset these proxy/privacy preferences in `about:config` too;
Firefox keeps preferences that have been removed from `user.js`.

The generated PAC returns only SOCKS5 for matches, so an unavailable proxy or
VPN blocks those requests. Everything else stays direct. DNS for SOCKS5 is
resolved inside the VPN; speculative DNS/connections and direct WebRTC are
disabled while this feature is enabled. WebRTC calls that need direct UDP may
stop working. Add separate login/CDN domains yourself if a site needs them;
only the listed domains and their subdomains use the VPN.

The PAC is an immutable local file, so loading it needs no network. Browser
settings or extensions that override proxy routing can still defeat this policy.
