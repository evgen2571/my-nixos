{ config, ... }:

{
  services.udisks2.enable = true;

  my = {
    desktop = {
      # Keep Niri and GNOME available alongside Umbriel.
      gnome.enable = true;
      niri.enable = true;
      umbriel.enable = true;
      noctaliaGreeter.enable = true;
      opentabletdriver.enable = false;
    };

    hardware = {
      bluetooth.enable = true;
      nvidia.enable = false;
      screenRecorder.enable = true;
    };

    system = {
      apps = {
        libreoffice.enable = true;
        steam.enable = true;
        obs.enable = false;
        vesktop.enable = true;
        waydroid.enable = true;
      };

      dev = {
        docker.enable = true;
        fish.enable = true;
      };

      files.thunar.enable = false;

      services = {
        browserVpnProxy.enable = true;
        lanMouse.enable = true;
        tailscale.enable = true;
        blueman.enable = true;
        syncthing.enable = true;

        networkNamespaces = {
          enable = true;

          namespaces.vpn = {
            enable = true;

            shared = {
              role = "client";

              privateKeyFile = (
                config.sops.secrets.vpn-wireguard-private-key.path or "/run/my-nixos-unavailable/wireguard"
              );

              address = "10.77.0.3/24";
              address6 = "fd77::3/64";
            };
          };
        };

        virtualization.enable = true;
      };
    };
  };

  my.primaryUser.home.settings = {
    xdg.userDirs.projects = "/home/${config.my.primaryUser.name}/dev";
    wallpapers.enable = true;
    programs.noctalia.settings.desktop_widgets = {
      enabled = false;
      widget_order = [ ];
    };
  };

  my.primaryUser.home.settings.my.user = {
    ai = {
      opencode.enable = true;
      skillshare.enable = true;
      codegraph.enable = true;

      chatgpt.enable = true;
      codex.enable = true;
      orca.enable = true;
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
      sonora.enable = true;
      youtubeMusic.enable = false;
      voxtype.enable = false;
      zenBrowser.enable = true;
    };

    desktop = {
      niriConfig = {
        enable = true;
        workspaceProfile = "laptop";
      };

      umbrielConfig = {
        enable = true;
        profile = "laptop";
      };
      cursors.enable = true;

      noctalia.enable = true;
      skwdWall.enable = true;

      screenRecorder.enable = true;
    };

    dev = {
      ssh.enable = true;
      ffmpeg.enable = true;
      workstation.enable = true;
      pycharm.enable = false;
      kitty.fontSize = "13.0";

      languages = {
        cpp.enable = true;
        java.enable = true;
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
