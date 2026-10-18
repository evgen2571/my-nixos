# Shared desktop host defaults

PC and laptop explicitly import `hosts/common/desktop.nix` from their local
`profile.nix`. Development aliases and trust come from narrow private overrides.
The server imports neither desktop selection. These files select existing options; they are outside
the discovered module roots and do not introduce an option interface.

Declarations retain ordinary Nix module priority, including the deferred
`my.primaryUser.home.settings` fragments. A future host change should remove a
selection from the shared file if it no longer represents both machines, or use
an explicit priority override deliberately; these are not silently weakened with
`mkDefault`. The workstation bundle retains its existing `mkDefault` semantics.

## Shared and host-specific choices

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
| Actline development aliases and CA trust | Private desktop override | Private host modules reference `../certs/actline-dev-rootCA.pem` in the private repository; the same trust is applied on PC/laptop only, never server |
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

These are feature selections, not service implementations. Changing them uses
normal generation activation and doesn't migrate application data. Historical
comparison code and build results for the extraction are in the
[issue #17 validation record](../archive/desktop-host-defaults-validation.md).
