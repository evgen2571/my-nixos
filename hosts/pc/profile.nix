{ ... }:

{
  my = {
    desktop = {
      niri.enable = true;
      # Keep only the active Niri desktop enabled here. Enabling Hyprland at the
      # same time also installs its portal backend on this host, which can race
      # with Niri/GNOME portals and break WebRTC screen sharing globally.
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
      hyprlandConfig.enable = false;
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
