{ config, ... }:

{
  imports = [
    ../common/desktop.nix
    ../common/actline-development.nix
  ];

  my = {
    desktop = {
      kdeplasma.enable = false;
      # Niri and Plasma remain selectable in the graphical greeter.
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
        zenlessZoneZero.enable = false;
      };

      services = {
        networkNamespaces = {
          enable = true;
          namespaces.vpn = {
            enable = true;
            shared = {
              role = "client";
              privateKeyFile = (
                config.sops.secrets.vpn-wireguard-private-key.path or "/run/my-nixos-unavailable/wireguard"
              );
              endpoint = "100.96.206.10:51877";
              address = "10.77.0.2/24";
              address6 = "fd77::2/64";
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
        virtualization.enable = false;
        sunshine.enable = false;
      };
    };
  };

  my.primaryUser.home.settings.my.user = {
    ai = {
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
      krita.enable = true;
      zenBrowser = {
        profilePath = "vrrqsw0h.evgen2571";
      };
    };

    desktop = {
      kdeplasmaConfig.enable = false;
      niriConfig = {
        workspaceProfile = "pc";
      };
      noctalia = {
        profile = "pc";
      };
    };

    dev = {
      ssh.serverIdentityFile = "~/.ssh/id_ed25519_nixos_pc";

      languages = {
        cpp.enable = true;
        java.enable = false;
        godot.enable = false;
        python.enable = true;
        rust.enable = true;
        unity.enable = false;
      };
    };
  };
}
