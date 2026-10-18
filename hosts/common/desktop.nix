{ ... }:

{
  my = {
    desktop = {
      niri.enable = true;
      noctaliaGreeter.enable = true;
    };

    system = {
      apps = {
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
      bruno.enable = false;
      chrome.enable = false;
      mpv.enable = true;
      obsidian.enable = true;
      osuLazer.enable = false;
      prismLauncher.enable = true;
      qimgv.enable = true;
      telegram.enable = true;
      youtubeMusic.enable = true;
      voxtype.enable = true;
      zenBrowser.enable = true;
    };
    desktop = {
      niriConfig.enable = true;
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
