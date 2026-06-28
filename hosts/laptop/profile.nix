{ ... }:

{
  my = {
    desktop = {
      active = "niri";
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
        vesktop.enable = true;
      };

      dev = {
        docker.enable = true;
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
      prismLauncher.enable = false;
      slack.enable = false;
      telegram.enable = true;
      youtubeMusic.enable = true;
      zenBrowser.enable = true;
    };

    desktop = {
      screenRecorder.enable = false;
    };

    dev = {
      ffmpeg.enable = true;
      workstation.enable = true;
      fish.configDir = ../../config/fish-laptop;
      kitty.configFile = ../../config/kitty/kitty-laptop.conf;
      starship.configFile = ../../config/starship/starship-laptop.toml;

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
