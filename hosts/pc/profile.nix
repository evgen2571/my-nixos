{ ... }:

{
  my = {
    desktop = {
      niri.enable = true;
      hyprland.enable = false;
      cinnamon.enable = false;
      ly.enable = true;
      opentabletdriver.enable = true;
    };

    hardware = {
      nvidia.enable = true;
    };

    system = {
      apps = {
        aagl.enable = true;
        kdeConnect.enable = true;
        steam.enable = true;
      };

      dev = {
        docker.enable = true;
        fish.enable = true;
      };

      files = {
        thunar.enable = false;
      };

      services = {
        ollama.enable = true;
        virtualization.enable = true;
        tailscale.enable = true;
      };
    };
  };

  home-manager.users.evgen2571.my.user = {
    apps = {
      anki.enable = true;
      bitwarden.enable = true;
      chrome.enable = false;
      notion.enable = true;
      obsidian.enable = true;
      osuLazer.enable = false;
      prismLauncher.enable = true;
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
      zoxide.enable = true;
      github.enable = true;
    };

    files = {
      dolphin.enable = true;
      yazi.enable = true;
    };
  };
}
