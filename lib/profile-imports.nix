{ modulePaths }:
{
  systemModules = [
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
    modulePaths.systemServices.vpnbookWireguardFailover

    modulePaths.hardware.bluetooth
    modulePaths.hardware.nvidia
    modulePaths.hardware.screenRecorder

    modulePaths.apps.aagl
    modulePaths.apps.kdeConnect
    modulePaths.apps.lutris
    modulePaths.apps.obs
    modulePaths.apps.steam

    modulePaths.coding.docker
    modulePaths.coding.fish

    modulePaths.fileManagers.thunar

    modulePaths.ai.ollama
  ];

  homeModules = [
    modulePaths.user.ai.codex
    modulePaths.user.ai.llamaCpp

    modulePaths.user.apps.anki
    modulePaths.user.apps.bitwarden
    modulePaths.user.apps.chrome
    modulePaths.user.apps.notion
    modulePaths.user.apps.obsidian
    modulePaths.user.apps.osuLazer
    modulePaths.user.apps.prismLauncher
    modulePaths.user.apps.telegram
    modulePaths.user.apps.vesktop
    modulePaths.user.apps.youtubeMusic
    modulePaths.user.apps.zenBrowser

    modulePaths.user.desktop.end4HyprlandDots
    modulePaths.user.desktop.hyprlandConfig
    modulePaths.user.desktop.niriConfig
    modulePaths.user.desktop.noctalia
    modulePaths.user.desktop.screenRecorder

    modulePaths.user.dev.devTools
    modulePaths.user.dev.fishConfig
    modulePaths.user.dev.git
    modulePaths.user.dev.ide
    modulePaths.user.dev.kitty
    modulePaths.user.dev.neovim
    modulePaths.user.dev.starship
    modulePaths.user.dev.tmux
    modulePaths.user.dev.vscode
    modulePaths.user.dev.zed
    modulePaths.user.dev.zoxide
    modulePaths.user.dev.github

    modulePaths.user.files.dolphin
    modulePaths.user.files.yazi
  ];
}
