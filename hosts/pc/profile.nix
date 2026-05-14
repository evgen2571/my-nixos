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

  home-manager.users.operator.my.user = {
    apps = {
      anki.enable = true;
      bitwarden.enable = true;
      chrome.enable = false;
      notion.enable = true;
      mpv.enable = true;
      obsidian.enable = true;
      osuLazer.enable = false;
      prismLauncher.enable = true;
      slack.enable = true;
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
      ffmpeg.enable = true;
      workstation.enable = true;
    };

    files = {
      dolphin.enable = true;
      yazi.enable = true;
    };
  };
}
