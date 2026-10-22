# Dolphin Places

Personal sidebar pins can be declared in a private NixOS module through
`my.primaryUser.home.settings`. Keep the paths, server URLs, and labels in the
private input; the public Dolphin module owns synchronization.

```nix
{ ... }: {
  my.primaryUser.home.settings = { config, ... }: {
    my.user.files.dolphin.places = [
      {
        url = "file://${config.home.homeDirectory}/pictures";
        name = "Pictures";
        icon = "folder-pictures";
      }
      {
        url = "sftp://example.invalid/files";
        name = "Remote files";
        icon = "folder-remote";
      }
    ];
  };
}
```

List order controls the managed group. URLs identify pins; each URL must be
unique. `icon` defaults to `folder`. `places = null` (the default) leaves Places
unmanaged; `places = []` removes only previously managed pins. A pin with the
same URL as an existing personal bookmark adopts its existing ID and metadata.
Unmanaged bookmarks and generated device entries remain intact. GUI edits to
managed pins are restored from Nix at the next Home Manager activation.

Close Dolphin before applying a rebuild, then reopen it. Activation merges the
list into the writable `$XDG_DATA_HOME/user-places.xbel` (normally
`~/.local/share/user-places.xbel`). Before the first change it saves the original
as `user-places.xbel.before-my-nixos`; it never overwrites that backup. Malformed
XML, symlinked targets, and detected concurrent changes cause a failure instead of
discarding existing state. Do not edit the backup into declarative source: it
contains runtime metadata as well as pins.

Private inputs and the generated bookmark list enter the local Nix store.
Never embed passwords or tokens in URLs. Build from the public repository using
the reviewed [private input override](../operations/deployment.md#select-reviewed-inputs).

Run `python3 tests/dolphin/places.py` or
`nix build .#checks.x86_64-linux.dolphin-places --no-link` for isolated merge tests.
