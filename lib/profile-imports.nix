{ modulePaths }:
let
  desktopSystemModules = [
    modulePaths.wm.role
    modulePaths.wm.niri
    modulePaths.wm.cinnamon
    modulePaths.wm.gnome
    modulePaths.wm.hyprland
    modulePaths.wm.ly
    modulePaths.wm.opentabletdriver
    modulePaths.wm.xserver
    modulePaths.wm.virtualization

    modulePaths.systemServices.tailscale
    modulePaths.systemServices.blueman
    modulePaths.systemServices.syncthing

    modulePaths.hardware.bluetooth
    modulePaths.hardware.nvidia
    modulePaths.hardware.screenRecorder

    modulePaths.apps.aagl
    modulePaths.apps.kdeConnect
    modulePaths.apps.lutris
    modulePaths.apps.obs
    modulePaths.apps.steam
    modulePaths.apps.vesktop

    modulePaths.coding.docker
    modulePaths.coding.fish

    modulePaths.fileManagers.thunar

    modulePaths.ai.ollama
  ];

  desktopHomeModules = [
    modulePaths.user.ai.codex
    modulePaths.user.ai.llamaCpp
    modulePaths.user.ai.opencode

    modulePaths.user.apps.anki
    modulePaths.user.apps.bitwarden
    modulePaths.user.apps.bruno
    modulePaths.user.apps.chrome
    modulePaths.user.apps.notion
    modulePaths.user.apps.mpv
    modulePaths.user.apps.obsidian
    modulePaths.user.apps.osuLazer
    modulePaths.user.apps.prismLauncher
    modulePaths.user.apps.slack
    modulePaths.user.apps.telegram
    modulePaths.user.apps.youtubeMusic
    modulePaths.user.apps.zenBrowser

    modulePaths.user.desktop.end4HyprlandDots
    modulePaths.user.desktop.hyprlandConfig
    modulePaths.user.desktop.niriConfig
    modulePaths.user.desktop.noctalia
    modulePaths.user.desktop.screenRecorder

    # Developer bundles define composition; leaf modules define tool-specific seams.
    modulePaths.user.dev.workstation
    modulePaths.user.dev.toolchains
    modulePaths.user.dev.terminalWorkflow
    modulePaths.user.dev.ffmpeg
    modulePaths.user.dev.fish
    modulePaths.user.dev.git
    modulePaths.user.dev.github
    modulePaths.user.dev.ssh
    modulePaths.user.dev.languages.cpp
    modulePaths.user.dev.languages.python
    modulePaths.user.dev.languages.rust
    modulePaths.user.dev.kitty
    modulePaths.user.dev.neovim
    modulePaths.user.dev.starship
    modulePaths.user.dev.tmux
    modulePaths.user.dev.vscode
    modulePaths.user.dev.zed
    modulePaths.user.dev.zoxide

    modulePaths.user.files.dolphin
    modulePaths.user.files.yazi
  ];
in
{
  desktop = {
    systemModules = desktopSystemModules;
    homeModules = desktopHomeModules;
  };

  server = {
    systemModules = [
      modulePaths.systemServices.vpnbookWireguardFailover
    ];

    homeModules = [
      modulePaths.user.dev.git
      modulePaths.user.dev.ssh
    ];
  };
}
