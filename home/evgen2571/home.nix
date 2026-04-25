{ modulePaths, ... }:
{
  home.username = "evgen2571";
  home.homeDirectory = "/home/evgen2571";

  imports = [
    modulePaths.wm.niriConfig
    modulePaths.wm.noctalia
    modulePaths.wm.screenRecorder

    # apps
    modulePaths.apps.zenBrowser
    modulePaths.apps.chrome
    modulePaths.apps.obsidian
    modulePaths.apps.vesktop
    modulePaths.apps.telegram
    modulePaths.apps.youtubeMusic
    modulePaths.apps.prismLauncher
    modulePaths.apps.bitwarden
    modulePaths.apps.osuLazer
    # modulePaths.apps.obs

    # file managers
    # modulePaths.fileManagers.dolphin
    modulePaths.fileManagers.yazi

    # coding
    modulePaths.coding.kitty
    modulePaths.coding.neovim
    modulePaths.coding.tmux
    modulePaths.coding.starship
    modulePaths.coding.fishConfig
    modulePaths.coding.devTools
    modulePaths.coding.git
    # modulePaths.coding.vscode
  ];

  home.sessionPath = [ "$HOME/.cargo/bin" ];

  home.enableNixpkgsReleaseCheck = false;
  home.stateVersion = "25.11";
}
