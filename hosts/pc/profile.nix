{ ... }:

{
  my = {
    desktop = {
      niri.enable = true;
      hyprland.enable = false;
      kdeplasma.enable = false;
      cinnamon.enable = false;
      ly.enable = true;
      # Niri and Plasma are available as separate sessions through Ly.
      gnome.enable = false;
      opentabletdriver.enable = true;
    };

    hardware = {
      bluetooth.enable = true;
      nvidia.enable = true;
      screenRecorder.enable = true;
    };

    system = {
      apps = {
        aagl.enable = false;
        kdeConnect.enable = false;
        steam.enable = true;
        obs.enable = true;
        vesktop.enable = true;
        zenlessZoneZero.enable = false;
      };

      dev = {
        docker.enable = true;
        fish.enable = true;
      };

      files = {
        thunar.enable = false;
      };

      services = {
        lanMouse.enable = true;
        ollama.enable = true;
        virtualization.enable = false;
        tailscale.enable = true;
        blueman.enable = true;
        syncthing.enable = true;
        sunshine.enable = false;
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
      bitwarden.enable = false;
      bruno.enable = false;
      chrome.enable = false;
      notion.enable = false;
      mpv.enable = true;
      obsidian.enable = true;
      osuLazer.enable = false;
      prismLauncher.enable = false;
      qimgv.enable = true;
      slack.enable = false;
      telegram.enable = true;
      youtubeMusic.enable = true;
      voxtype.enable = true;
      zenBrowser.enable = true;
    };

    desktop = {
      kdeplasmaConfig.enable = false;
      niriConfig = {
        enable = true;
        workspaceProfile = "pc";
      };
      # Hyprland is not installed on this host, so do not deploy its dotfiles.
      hyprlandConfig.enable = false;
      end4HyprlandDots.enable = false;
      noctalia.enable = true;
      screenRecorder.enable = true;
    };

    dev = {
      ffmpeg.enable = true;
      workstation.enable = true;

      languages = {
        cpp.enable = true;
        java.enable = false;
        godot.enable = false;
        python.enable = true;
        rust.enable = true;
        unity.enable = false;
      };
    };

    files = {
      dolphin.enable = true;
      yazi.enable = true;
    };
  };
}
