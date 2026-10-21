# Approved final module tree

Reviewed and approved on 2026-10-20 for the remaining #49 stages, following the
maintainer's request to review and approve the layout. The implementation is now complete; see [the final handoff](final-architecture.md).
`inventory.json` is the exhaustive file mapping.

Standards review: no findings. Spec review against #49/#50: no blockers.
The review checked all 75 unique typed entry targets, complete baseline module
and home-file coverage, explicit infrastructure exclusion, and exact target-tree
coverage. Ordered desktop system/home counts remain 23/47; server counts remain
12/23. Fish and Kitty are the only intentional shared consolidation targets.

Niri/Fish colocation, single-file simplifications, retained complex-feature
helpers, unconditional personal SSH and distinct server-baseline/server-base
responsibilities follow the comparison contract. Typed discovery must preserve
those boundaries and the recorded order/eligibility. This approval covers the
layout and mapping; later implementation still needs equivalence verification.
Merge and live activation remain separate decisions.

```
modules/ai/codegraph.home.nix
modules/ai/codex.home.nix
modules/ai/llama-cpp.home.nix
modules/ai/opencode.home.nix
modules/ai/orca.home.nix
modules/ai/skillshare.home.nix
modules/apps/anki.home.nix
modules/apps/bruno.home.nix
modules/apps/chrome.home.nix
modules/apps/krita.home.nix
modules/apps/lutris.nixos.nix
modules/apps/mpv.home.nix
modules/apps/obs.nixos.nix
modules/apps/obsidian.home.nix
modules/apps/osu-lazer.home.nix
modules/apps/prism-launcher.home.nix
modules/apps/qimgv.home.nix
modules/apps/steam.nixos.nix
modules/apps/telegram.home.nix
modules/apps/vesktop.nixos.nix
modules/apps/voxtype.home.nix
modules/apps/waydroid.nixos.nix
modules/apps/youtube-music.home.nix
modules/apps/zen-browser.home.nix
modules/core/desktop-baseline.nixos.nix
modules/core/primary-user.home.nix
modules/core/primary-user.nixos.nix
modules/core/secrets.nixos.nix
modules/core/server-baseline.nixos.nix
modules/deployment/install-preflight.patch
modules/deployment/nixos.nix
modules/deployment/preflight.sh
modules/deployment/rebuild-preflight.patch
modules/deployment/rebuild-tests.patch
modules/desktop/gnome.nixos.nix
modules/desktop/niri/home.nix
modules/desktop/niri/nixos.nix
modules/desktop/noctalia-greeter.nixos.nix
modules/desktop/noctalia/config.nix
modules/desktop/noctalia/home.nix
modules/desktop/opentabletdriver.nixos.nix
modules/desktop/screen-recorder.home.nix
modules/desktop/screen-recorder.nixos.nix
modules/desktop/xserver.nixos.nix
modules/dev/bb.home.nix
modules/dev/bundles/terminal-workflow.home.nix
modules/dev/bundles/toolchains.home.nix
modules/dev/bundles/workstation.home.nix
modules/dev/docker.nixos.nix
modules/dev/ffmpeg.home.nix
modules/dev/fish/home.nix
modules/dev/fish/nixos.nix
modules/dev/git.home.nix
modules/dev/github.home.nix
modules/dev/kitty.home.nix
modules/dev/languages/cpp.home.nix
modules/dev/languages/godot.home.nix
modules/dev/languages/java.home.nix
modules/dev/languages/python.home.nix
modules/dev/languages/rust.home.nix
modules/dev/languages/unity.home.nix
modules/dev/neovim/config.nix
modules/dev/neovim/home.nix
modules/dev/pycharm.home.nix
modules/dev/ssh.home.nix
modules/dev/starship.home.nix
modules/dev/tmux/home.nix
modules/dev/tmux/project-list.sh
modules/dev/vscode.home.nix
modules/dev/zed.home.nix
modules/dev/zoxide.home.nix
modules/files/dolphin.home.nix
modules/files/thunar.nixos.nix
modules/files/yazi.home.nix
modules/hardware/bluetooth.nixos.nix
modules/hardware/nvidia.nixos.nix
modules/server/base.nixos.nix
modules/server/docker-host.nixos.nix
modules/server/ssh.nixos.nix
modules/server/storage.nixos.nix
modules/server/syncthing.nixos.nix
modules/services/blueman.nixos.nix
modules/services/lan-mouse.nixos.nix
modules/services/network-namespaces/doctor.nix
modules/services/network-namespaces/doctor.py
modules/services/network-namespaces/launcher.nix
modules/services/network-namespaces/migration/desktop-provider-guard.sh
modules/services/network-namespaces/migration/prepare-rollback.sh
modules/services/network-namespaces/migration/rollback.sh
modules/services/network-namespaces/namespace.nix
modules/services/network-namespaces/nixos.nix
modules/services/network-namespaces/shared.nix
modules/services/sunshine.nixos.nix
modules/services/syncthing.nixos.nix
modules/services/tailscale.nixos.nix
modules/services/virtualization.nixos.nix
```

Private helpers remain inside their owning complex feature; they are not discovered.
Program-native `config/` and packaging sources retain their paths.
