{ ... }:

{
  my = {
    desktop = {
      niri.enable = true;
      hyprland.enable = false;
      cinnamon.enable = false;
      ly.enable = true;
      opentabletdriver.enable = false;
    };

    hardware = {
      bluetooth.enable = true;
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
        thunar.enable = false;
      };

      services = {
        ollama.enable = true;
        virtualization.enable = false;
        tailscale.enable = true;
        blueman.enable = true;
      };
    };
  };

  home-manager.users.evgen2571.my.user = {
    ai = {
      opencode.enable = true;
      codex.enable = false;
    };

    apps = {
      anki.enable = true;
      bitwarden.enable = true;
      bruno.enable = true;
      chrome.enable = false;
      notion.enable = false;
      mpv.enable = true;
      obsidian.enable = true;
      osuLazer.enable = false;
      prismLauncher.enable = false;
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
        workspacesFile = "workspaces-laptop.kdl";
      };
      noctalia.enable = true;
      screenRecorder.enable = false;
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
