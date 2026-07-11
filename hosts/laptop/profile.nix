{ ... }:

{
  my = {
    desktop = {
      niri.enable = true;
      hyprland.enable = false;
      cinnamon.enable = false;
      ly.enable = true;
      # Niri is the active session; keep the portal backend unambiguous.
      gnome.enable = false;
      opentabletdriver.enable = false;
    };

    hardware = {
      bluetooth.enable = true;
      nvidia.enable = false;
      screenRecorder.enable = true;
    };

    system = {
      apps = {
        aagl.enable = false;
        kdeConnect.enable = false;
        obs.enable = true;
        steam.enable = true;
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

  my.primaryUser.home.settings.my.user = {
    ai = {
      opencode.enable = false;
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
      prismLauncher.enable = true;
      slack.enable = false;
      telegram.enable = true;
      youtubeMusic.enable = true;
      zenBrowser.enable = true;
    };

    desktop = {
      niriConfig = {
        enable = true;
        workspaceProfile = "laptop";
      };
      hyprlandConfig.enable = false;
      end4HyprlandDots.enable = false;
      noctalia.enable = true;
      screenRecorder.enable = true;
    };

    dev = {
      ffmpeg.enable = true;
      workstation.enable = true;
      kitty.fontSize = "13.0";

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
