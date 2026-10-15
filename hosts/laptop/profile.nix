{ config, ... }:

{
  my = {
    desktop = {
      niri.enable = true;
      hyprland.enable = false;
      cinnamon.enable = false;
      noctaliaGreeter.enable = true;
      # Niri is the active session; keep the portal backend unambiguous.
      gnome.enable = true;
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
        waydroid.enable = true;
      };

      dev = {
        docker.enable = true;
        fish.enable = true;
      };

      files = {
        thunar.enable = false;
      };

      services = {
        networkNamespaces = {
          enable = true;
          namespaces.vpn = {
            enable = true;
            shared = {
              role = "client";
              privateKeyFile = config.sops.secrets.vpn-wireguard-private-key.path;
              endpoint = "100.96.206.10:51877";
              address = "10.77.0.3/24";
              address6 = "fd77::3/64";
              peers = [
                {
                  publicKey = (import ../vpn-public-keys.nix).server;
                  allowedIPs = [
                    "0.0.0.0/0"
                    "::/0"
                  ];
                }
              ];
            };
          };
        };
        lanMouse.enable = true;
        ollama.enable = true;
        virtualization.enable = true;
        tailscale.enable = true;
        blueman.enable = true;
        syncthing.enable = true;
      };
    };
  };

  my.primaryUser.home.settings.my.user = {
    ai = {
      opencode.enable = true;
      codex = {
        enable = true;
        networkNamespace = "vpn";
      };
      orca = {
        enable = true;
        networkNamespace = "vpn";
      };
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
      zenBrowser = {
        enable = true;
        profilePath = "it4r6j1f.evgen2571";
      };
    };

    desktop = {
      niriConfig = {
        enable = true;
        workspaceProfile = "laptop";
      };
      hyprlandConfig.enable = false;
      end4HyprlandDots.enable = false;
      noctalia = {
        enable = true;
        profile = "laptop";
      };
      screenRecorder.enable = true;
    };

    dev = {
      ffmpeg.enable = true;
      pycharm.enable = false;
      workstation.enable = true;
      ssh.serverIdentityFile = "~/.ssh/id_ed25519_nixos_lp";
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
