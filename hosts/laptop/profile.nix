{ config, ... }:

{
  services.udisks2.enable = true;

  my = {
    desktop = {
      # Niri is the active session; keep the portal backend unambiguous.
      gnome.enable = true;
      niri.enable = true;
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
        obs.enable = true;
        vesktop.enable = true;
        waydroid.enable = true;
      };

      dev = {
        docker.enable = true;
        fish.enable = true;
      };

      files.thunar.enable = false;

      services = {
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

  my.primaryUser.home.settings.wallpapers.enable = true;

  my.primaryUser.home.settings.my.user = {
    ai = {
      opencode.enable = true;
      skillshare.enable = true;
      codegraph.enable = true;

      codex = {
        enable = true;
        networkNamespace = "vpn";
      };

      orca = {
        enable = true;
        networkNamespace = "vpn";
      };
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
      niriConfig = {
        enable = true;
        workspaceProfile = "laptop";
      };

      noctalia = {
        enable = true;
        profile = "laptop";
      };

      screenRecorder.enable = true;
    };

    dev = {
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
