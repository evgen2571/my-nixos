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
	modulePaths.wm.virtualization

	modulePaths.systemServices.tailscale
	modulePaths.systemServices.bluetooth

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

  my = {
    desktop = {
      niri.enable = true;
      hyprland.enable = false;
      cinnamon.enable = false;
      ly.enable = true;
      opentabletdriver.enable = false;
    };

    hardware = {
      nvidia.enable = false;
    };

    system = {
      apps = {
        aagl.enable = false;
        kdeConnect.enable = false;
        steam.enable = true;
      };

      dev = {
        docker.enable = true;
        fish.enable = true;
      };

      files = {
        thunar.enable = true;
      };

      services = {
        ollama.enable = true;
        virtualization.enable = false;
		tailscale.enable = true;
		bluetooth.enable = true;
      };
    };
  };

  home-manager.users.evgen2571 = {
    imports = [
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

    my.user = {
      apps = {
        anki.enable = true;
        bitwarden.enable = true;
        chrome.enable = false;
        notion.enable = false;
        obsidian.enable = true;
        osuLazer.enable = false;
        prismLauncher.enable = false;
        telegram.enable = true;
        vesktop.enable = true;
        youtubeMusic.enable = true;
        zenBrowser.enable = true;
      };

      desktop = {
        end4HyprlandDots.enable = false;
        hyprlandConfig.enable = false;
        niriConfig = {
          enable = true;
          workspacesFile = "workspaces-pc.kdl";
        };
        noctalia.enable = true;
        screenRecorder.enable = false;
      };

      dev = {
        devTools.enable = true;
        fishConfig.enable = true;
        git.enable = true;
        kitty.enable = true;
        neovim.enable = true;
        starship.enable = true;
        tmux.enable = true;
        zoxide.enable = true;
        github.enable = true;
      };

      files = {
        yazi.enable = true;
      };
    };
  };
}
