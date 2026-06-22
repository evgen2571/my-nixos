{ ... }:

{
  my = {
    desktop = {
      niri.enable = true;
      hyprland.enable = true;
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
        aagl.enable = false;
        kdeConnect.enable = true;
        steam.enable = true;
        obs.enable = true;
        vesktop.enable = true;
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
        syncthing.enable = true;
      };
    };
  };

  home-manager.users.evgen2571.my.user = {
    ai = {
      opencode.enable = false;
      codex.enable = false;
    };

    apps = {
      anki.enable = true;
      bitwarden.enable = false;
      bruno.enable = true;
      chrome.enable = false;
      notion.enable = false;
      mpv.enable = true;
      obsidian.enable = true;
      osuLazer.enable = false;
      prismLauncher.enable = false;
      slack.enable = false;
      telegram.enable = true;
      youtubeMusic.enable = true;
      zenBrowser.enable = true;
    };

    desktop = {
      end4HyprlandDots.enable = false;
      hyprlandConfig.enable = true;
      niriConfig = {
        enable = true;
        workspacesFile = "workspaces-pc.kdl";
      };
      noctalia.enable = true;
      screenRecorder.enable = false;
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
