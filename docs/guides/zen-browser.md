# Declarative Zen Browser

Both `nixos-pc` and `nixos-lp` install Zen through
[zen-browser-flake](https://github.com/0xc000022070/zen-browser-flake).
Home Manager provides native declarations for spaces, nested pin folders,
Essentials, Sine mods and URL-based workspace routing.

## Files

- `modules/user-apps/zen-browser.nix`: package and optional profile management.
- `config/zen/profile.nix`: shared spaces, pins, Essentials, routes and Sine.
- `config/zen/chatgpt-projects.nix`: user-specific ChatGPT project pins
  (contains the nine project URLs currently provided).
- `hosts/pc/profile.nix`, `hosts/laptop/profile.nix`: enable separately per host.

## Shared workspace layout

- **ChatGPT**: ChatGPT home and nine direct project pins in
  `chatgpt-projects.nix`.
- **Development**: folders for Competitive Programming (Codeforces, CSES,
  AtCoder, CP-Algorithms, USACO Guide, LeetCode), Documentation (NixOS, Home
  Manager, C++/Python/Rust/MDN), ML and Research, and Developer Tools.
- **Chill / Watch**: Watching (YouTube, Kinopoisk, YouTube Music) and Anime
  (AniList, Shikimori, MyAnimeList).
- **Essentials**: GitHub and Google Calendar, visible in all workspaces.

### ChatGPT project pins

Direct ChatGPT Project URLs cannot be inferred from project names. To add more
projects, copy each address from ChatGPT and enter it in
`config/zen/chatgpt-projects.nix`:

```nix
{
  "Actline" = {
    id = "<a new stable UUID (uuidgen)>";
    url = "<the real URL copied from your ChatGPT project>";
    position = 200;
  };
}
```

The placeholders above are documentation only; do not activate them verbatim.
If this Git repository is public, names/URLs disclose project metadata (though
private content remains access-controlled).

### Layout and keyboard shortcuts

The profile uses Zen's **Sidebar and Top Toolbar** layout:

```nix
settings = {
  "zen.view.use-single-toolbar" = false;
  "zen.view.sidebar-expanded" = true;
};
```

Press **Ctrl + backtick** to toggle compact mode:

```nix
keyboardShortcutsVersion = 21; # Zen 1.22.2b in the pinned flake
keyboardShortcuts = [
  {
    id = "zen-compact-mode-toggle";
    key = "`";
    modifiers.control = true;
  }
];
```

Additional bindings can be appended to `keyboardShortcuts` by shortcut ID,
without replacing all other defaults. The shortcut schema version is pinned
to Zen 1.22.2b's value; after updating the browser, inspect
`zen.keyboard.shortcuts.version` in `about:config` and adjust if necessary.

**Close Zen before activation.** The flake modifies
`zen-keyboard-shortcuts.json` and skips the update if the file does not yet
exist (open Zen once to let it create the profile). You can inspect current
bindings in `Settings > Keyboard Shortcuts`. Your Niri configuration uses
`Alt+grave` for window cycling, not `Ctrl+grave`, so there is no declared
Niri conflict.

### Declarative space routing

The pinned Zen flake supports `spaces.<name>.routes` and writes
`zen-space-routing.jsonlz4`. For example:

```nix
spaces.Development.routes.CSES.reference = "cses.fi";
```

Rules select the target workspace for **new tabs**, not existing tabs.
The simple URL substring matching is intentional. GitHub and Google Calendar
are Essentials with no forced route, since you may use them in any space.
Unmatched external links open in `most-recent-space`. Manual routes that are
not declared in Nix are preserved (`spaceRouting.force = false`).

## Safe activation (one host at a time)

1. Back up your entire Zen directory after closing the browser:

   ```sh
   cp -a ~/.config/zen ~/zen-backup-$(date +%Y%m%d-%H%M%S)
   ```

2. Open `about:profiles`, find the **Root Directory** of your current default
   profile, and record its last directory component, for example
   `abcdefgh.Default Profile`. Then close Zen.
3. Review the new workspace and tab UUIDs in `config/zen/profile.nix`. If
   you already have the same spaces/pins, use their current UUIDs from
   `zen-sessions.jsonlz4` (inspect with a mozlz4-compatible decoder).
   A changed UUID creates a new space/tab rather than adopting the original.
4. Set `zenBrowser` in the existing
   `my.primaryUser.home.settings.my.user.apps` of each host's profile:

   ```nix
   zenBrowser = {
     enable = true;
     profilePath = "abcdefgh.Default Profile"; # use the actual name per host
   };
   ```

5. Close Zen and execute:

   ```sh
   sudo nixos-rebuild build --flake .#nixos-pc
   sudo nixos-rebuild switch --flake .#nixos-pc
   ```

   Use `nixos-lp` for the laptop, with its own profile directory name.

Until `profilePath` is set, Zen remains installed as before and none of the
declarative profile edits are activated.

## Sine and state safety

`sine.enable = true` enables Sine's engine. Add Sine store directory IDs to
`sine.mods` (for example `"Arc-2.0"`). The engine is flake-pinned but
individual mods are fetched from the live remote store during activation and
are **not immutable, content-hash-pinned builds**. Sine preferences modified in
the UI are not fully managed by this file.

Always close Zen before rebuild/switch with session-file changes; the flake
can skip writing while Zen owns the profile lock.

Keep `spacesForce = false`, `pinsForce = false`, and
`spaceRouting.force = false` while adopting your current setup. History,
cookies, logins, manually installed add-ons and session data stay in the
writable profile: do not commit or symlink the whole profile into the Nix store.

References: upstream `examples/10-pinned-tabs.nix` and
`examples/18-space-routing.nix`.
