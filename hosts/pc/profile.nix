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
      bluetooth.enable = true;
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

      languages = {
        cpp.enable = true;
        python.enable = true;
        rust.enable = true;
      };
    };

    files = {
      dolphin.enable = true;
      yazi.enable = true;
    };
  };
}
