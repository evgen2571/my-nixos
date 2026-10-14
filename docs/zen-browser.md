# Declarative Zen Browser

Zen is installed on both `nixos-pc` and `nixos-lp` using the existing
[zen-browser-flake](https://github.com/0xc000022070/zen-browser-flake).
Its Home Manager module can manage spaces, pinned tabs, Essentials, and Sine
mods without custom session-file scripts.

## Configuration

- `modules/user-apps/zen-browser.nix` — browser package and opt-in profile
  management.
- `config/zen/profile.nix` — shared desired workspaces, pinned tabs, Essentials,
  and Sine mods.
- `hosts/pc/profile.nix` and `hosts/laptop/profile.nix` — enable profile
  management independently via `my.user.apps.zenBrowser.profilePath`.

The supplied Personal/Development/Study spaces and URLs are **examples**, not
a snapshot of the existing Zen installation. Change them to the desired layout
before activating the profile on either host.

## Adopt an existing profile (one host at a time)

1. Close Zen, then back up its directory:

   ```sh
   cp -a ~/.config/zen ~/zen-backup-$(date +%Y%m%d-%H%M%S)
   ```

2. Start Zen and open `about:profiles`. Under the current **default profile**,
   note its **Root Directory**. Copy only the final directory name (for example
   `abcdefgh.Default Profile`). Then close Zen again.

3. Before enabling, edit `config/zen/profile.nix` to match the actual
   workspaces and tabs you want to keep. Keep their existing IDs: changing an
   ID creates a different space/tab instead of adopting the existing one. The
   IDs live in `zen-sessions.jsonlz4` inside the profile and can be inspected
   with an mozlz4-compatible decoder. Do not use the example UUIDs if your
   workspace/tab already exists. If unsure, first adopt just one space and
   leave `spacesForce` / `pinsForce` false.

4. Set this **in the applicable host profile**, inside the existing
   `my.primaryUser.home.settings.my.user.apps` block:

   ```nix
   zenBrowser = {
     enable = true;
     profilePath = "abcdefgh.Default Profile"; # replace per host
   };
   ```

   Repeat on the other host using **its own** profile path. The same desired
   workspace IDs may be shared across hosts, but the profile directory names
   normally differ.

5. Keep Zen closed during evaluation and activation:

   ```sh
   sudo nixos-rebuild build --flake .#nixos-pc
   sudo nixos-rebuild switch --flake .#nixos-pc
   ```

   Substitute `nixos-lp` on the laptop. Check the workspaces, pins, Essentials
   and Sine UI after reopening Zen.

Without `profilePath`, the browser continues to be installed as before; the
declarative profile is **not activated**. This prevents a rebuild from creating
an accidental replacement default profile.

## Sine mods

Sine's engine is enabled with `sine.enable = true` once profile management is
activated. Put mod IDs in `config/zen/profile.nix`:

```nix
sine.mods = [ "Arc-2.0" ];
```

These are Sine store directory IDs, not arbitrary GitHub repository URLs.
Supported mods are installed/updated by the Zen flake's activation scripts.
Mods installed manually in Sine remain separate. `sine.mods` is not the same
as the flake's regular Zen theme-store `mods` option; do not set both.

The Sine engine/bootloader versions are pinned by the Zen flake input. **Mod
downloads occur from a live remote store at activation**, so this is a
declarative *list of selected mods*, not a fully immutable, hash-pinned mod
build. Sine preference changes made in the UI are not fully declared here.

## Safety / limitations

- Leave `spacesForce` and `pinsForce` set to `false` during adoption; existing
  entries are preserved. Forcing deletion/demotion is only appropriate when
  the Nix file exhaustively describes what should remain.
- **Close Zen before switching** when spaces/pins are managed. Zen keeps session
  data in memory, and the flake's activation can skip writes while it is open.
- The profile directory includes history, cookies, passwords, and session
  state: **never commit it to Git**. Do not symlink the whole profile to the
  Nix store.
- Logins, cookies, browsing history, manually installed extensions, and
  per-mod Sine preferences are not made declarative by this module.
- If moving from another installation layout, confirm where `about:profiles`
  says the live profile is stored; the flake expects `~/.config/zen`.

Reference: [Zen Browser flake examples](https://github.com/0xc000022070/zen-browser-flake/tree/main/examples).
