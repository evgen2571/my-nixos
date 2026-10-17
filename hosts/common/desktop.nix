{ ... }:

{
  my = {
    desktop = {
      niri.enable = true;
      hyprland.enable = false;
      cinnamon.enable = false;
      noctaliaGreeter.enable = true;
    };

    system = {
      apps = {
        aagl.enable = false;
        kdeConnect.enable = false;
        steam.enable = true;
        obs.enable = true;
        vesktop.enable = true;
      };
      dev = {
        docker.enable = true;
        fish.enable = true;
      };
      files.thunar.enable = false;
      services = {
        lanMouse.enable = true;
        ollama.enable = true;
        tailscale.enable = true;
        blueman.enable = true;
        syncthing.enable = true;
      };
    };
  };

  my.primaryUser.home.settings.my.user = {
    ai = {
      opencode.enable = true;
      skillshare.enable = true;
      codegraph.enable = true;
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
      prismLauncher.enable = true;
      qimgv.enable = true;
      slack.enable = false;
      telegram.enable = true;
      youtubeMusic.enable = true;
      voxtype.enable = true;
      zenBrowser.enable = true;
    };
    desktop = {
      niriConfig.enable = true;
      hyprlandConfig.enable = false;
      end4HyprlandDots.enable = false;
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
