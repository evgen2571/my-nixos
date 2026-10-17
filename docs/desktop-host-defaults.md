# Shared desktop host defaults

PC and laptop explicitly import `hosts/common/desktop.nix` and
`hosts/common/actline-development.nix` from their local `profile.nix`.
The server imports neither. These files select existing options; they are outside
the discovered module roots and do not introduce an option interface.

Declarations retain ordinary Nix module priority, including the deferred
`my.primaryUser.home.settings` fragments. A future host change should remove a
selection from the shared file if it no longer represents both machines, or use
an explicit priority override deliberately; these are not silently weakened with
`mkDefault`. The workstation bundle retains its existing `mkDefault` semantics.

## Inventory for issue #17

This inventory covers both original profiles and the repeatable declarations in
both `configuration.nix` files. “Host override” below means a visible host-specific
selection, not an added `mkForce`.

| Settings | Classification | Owner / rationale |
| --- | --- | --- |
| Niri on, Hyprland/Cinnamon off, Noctalia greeter on | Shared stable default | `hosts/common/desktop.nix` |
| System apps: AAGL/KDE Connect off; Steam/OBS/Vesktop on | Shared stable default | Shared desktop selection; Steam remains enabled on both |
| System Docker/Fish on, Thunar off | Shared stable default | Shared desktop selection |
| LAN Mouse, Ollama, Tailscale, Blueman, Syncthing on | Shared stable default | Shared desktop selection; no service implementation changes |
| User OpenCode, Skillshare, CodeGraph on | Shared stable default | Shared desktop selection |
| User apps: Anki, mpv, Obsidian, Prism Launcher, qimgv, Telegram, YouTube Music, Voxtype, Zen on | Shared stable default | Shared desktop selection |
| User apps: Bitwarden, Bruno, Chrome, Notion, osu!lazer, Slack off | Shared stable default | Shared desktop selection |
| User Niri/Noctalia/screen recorder on; Hyprland/end4 dotfiles off | Shared stable default | Shared desktop selection; profiles still choose workspace/Noctalia variants |
| FFmpeg/workstation, Dolphin/Yazi on | Shared stable default | Shared desktop selection; bundle implementation unchanged |
| Actline aliases and public CA | Shared stable default | Separate `hosts/common/actline-development.nix`, explicitly selected by both profiles; same aliases and unchanged public CA content under `hosts/common/certs/`, no server trust expansion |
| GNOME, OpenTabletDriver, PC-only Plasma selection | Host override | Local desktop blocks; GNOME differs |
| Bluetooth, NVIDIA, hardware screen recorder | Intentionally duplicated for clarity/safety | Local hardware blocks, including identical toggles; GPU ownership remains visible |
| PC Zenless Zone Zero/Sunshine off, laptop Waydroid on; virtualization differs | Host override | Local system blocks |
| Entire networkNamespaces block and Codex/Orca enablement plus namespace | Intentionally duplicated for clarity/safety | Local profiles preserve transport, peer, key path, routing and fail-closed selection together |
| Zen profile path, Niri workspace profile, Noctalia profile, SSH identity | Host override | Local user blocks |
| PC Krita on, KDE dotfiles off; laptop PyCharm off, Kitty font size | Host override | Local user preferences |
| Language selections (including identical C++/Python/Rust) | Intentionally duplicated for clarity | Local language blocks keep each host's toolchain choices observable; Java differs, PC Godot/Unity off |
| Primary-user enable/name/description/shell/Git identity | Intentionally duplicated for clarity | Local `configuration.nix`; account ownership stays explicit alongside differing supplementary groups |
| Swapfile and size, system state version | Intentionally duplicated for clarity/safety | Local machine storage and lifecycle settings |
| Hardware/secrets/base-module imports | Intentionally duplicated for clarity/safety | Local `configuration.nix`; do not change discovery or secret ownership |
| Boot/kernel, hostname, fingerprint/PAM, PC printing/nm-applet/rtkit/uinput/packages/cache settings, laptop libinput | Host override | Local `configuration.nix`; machine/security behavior untouched |

Only declarative selections move. Application source files, mutable runtime
state, VPN implementations and host hardware definitions are unchanged. Deploy
through the usual separately authorized generation activation; this refactor
requires no runtime migration.

## Evaluated option comparison

The pre-edit baseline is commit `4070d7c4824207065e7ec24cd32ccbb6982986cd`.
All three host matrices were equal before and after the extraction, including
Steam enabled on both desktop hosts. The comparison evaluates
`my.desktop`, `my.hardware`, `my.system`, and the primary user's evaluated
Home Manager `my.user` (the result of `my.primaryUser.home.settings`), plus
`networking.extraHosts`, public CA content hashes, greetd settings,
display-manager default session/packages, Niri and greetd/sudo PAM settings.
Derivations are represented by their derivation paths; public certificate paths
are compared by content hash. No private key or secret contents are read.

The temporary matrix expression used for both captures was:

```nix
flake:
let
  lib = flake.inputs.nixpkgs.lib;
  normalize = value:
    if lib.isDerivation value then value.drvPath
    else if builtins.isPath value then builtins.hashFile "sha256" value
    else if builtins.isAttrs value then lib.mapAttrs (_: normalize) (builtins.removeAttrs value [ "_module" ])
    else if builtins.isList value then map normalize value
    else value;
  matrix = c: normalize {
    desktop = c.my.desktop or {};
    hardware = c.my.hardware or {};
    system = c.my.system or {};
    user = c.home-manager.users.${c.my.primaryUser.name}.my.user;
    extraHosts = c.networking.extraHosts;
    certificates = map (builtins.hashFile "sha256") c.security.pki.certificateFiles;
    session = {
      greetd = if c.services.greetd.enable then { inherit (c.services.greetd) enable settings; } else { enable = false; };
      displayManager = { inherit (c.services.displayManager) defaultSession sessionPackages; };
      niri = c.programs.niri or {};
      pam = lib.genAttrs (builtins.filter (name: builtins.hasAttr name c.security.pam.services) [ "greetd" "sudo" ]) (name: { inherit (c.security.pam.services.${name}) fprintAuth enableGnomeKeyring text; });
    };
  };
in lib.mapAttrs (_: host: matrix host.config) flake.nixosConfigurations
```

Capture before editing and again after staging new flake source files:

```sh
nix eval --impure --json --expr 'import /tmp/my-nixos-17/matrix.nix (builtins.getFlake (toString ./.))' > /tmp/my-nixos-17/before.json
# Repeat with after.json, then compare:
cmp /tmp/my-nixos-17/before.json /tmp/my-nixos-17/after.json
```

Validation completed without live activation:

- `cmp /tmp/my-nixos-17/before.json /tmp/my-nixos-17/after.json`: identical for all three hosts.
- `nix fmt hosts/common/desktop.nix hosts/common/actline-development.nix hosts/pc/profile.nix hosts/laptop/profile.nix hosts/pc/configuration.nix hosts/laptop/configuration.nix`: passed. Bare `nix fmt` failed because this formatter expects file arguments.
- `nix flake check --no-build`: passed (evaluation only).
- `nix flake check`: passed (all registered flake checks).
- `nix build .#nixosConfigurations.nixos-pc.config.system.build.toplevel .#nixosConfigurations.nixos-lp.config.system.build.toplevel --no-link`: passed for both desktops.
- `git diff --check` and relative documentation link validation: passed.

No host activation, service restart, runtime/UI check or Steam runtime test was
performed. The laptop Steam runtime issue remains tracked separately in #16.
