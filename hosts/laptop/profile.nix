{ modulePaths, ... }:

{
  imports = [
    modulePaths.wm.niri
    modulePaths.wm.cinnamon
    modulePaths.wm.gnome
    modulePaths.wm.hyprland
    modulePaths.wm.ly
    modulePaths.wm.opentabletdriver
    modulePaths.wm.xserver

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
    modulePaths.wm.virtualization
  ];

  my = {
    desktop = {
      niri.enable = true;
      ly.enable = true;
    };

    system = {
      apps = {
        steam.enable = true;
      };

      dev = {
        fish.enable = true;
      };

      services = {
        ollama.enable = true;
      };
    };
  };

  home-manager.users.operator = {
    imports = [
      modulePaths.user.ai.codex
      modulePaths.user.ai.llamaCpp

      modulePaths.user.apps.bitwarden
      modulePaths.user.apps.chrome
      modulePaths.user.apps.obsidian
      modulePaths.user.apps.osuLazer
      modulePaths.user.apps.prismLauncher
      modulePaths.user.apps.telegram
      modulePaths.user.apps.vesktop
      modulePaths.user.apps.youtubeMusic
      modulePaths.user.apps.zenBrowser

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

      modulePaths.user.files.dolphin
      modulePaths.user.files.yazi
    ];

    my.user = {
      apps = {
        bitwarden.enable = true;
        chrome.enable = true;
        obsidian.enable = true;
        osuLazer.enable = true;
        prismLauncher.enable = true;
        telegram.enable = true;
        vesktop.enable = true;
        youtubeMusic.enable = true;
        zenBrowser.enable = true;
      };

      desktop = {
        niriConfig.enable = true;
        noctalia.enable = true;
        screenRecorder.enable = true;
      };

      dev = {
        devTools.enable = true;
        fishConfig.enable = true;
        git.enable = true;
        kitty.enable = true;
        neovim.enable = true;
        starship.enable = true;
        tmux.enable = true;
      };

      files = {
        yazi.enable = true;
      };
    };
  };
}
