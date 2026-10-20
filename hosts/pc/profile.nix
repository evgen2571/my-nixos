{ config, ... }:

{
  imports = [
    ../common/desktop.nix
  ];

  my = {
    desktop = {
      gnome.enable = false;
      opentabletdriver.enable = true;
    };

    hardware = {
      bluetooth.enable = true;
      nvidia.enable = true;
      screenRecorder.enable = true;
    };

    system = {
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
              address = "10.77.0.2/24";
              address6 = "fd77::2/64";
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
    };

    desktop = {
      niriConfig = {
        workspaceProfile = "pc";
      };
      noctalia = {
        profile = "pc";
      };
    };

    dev = {
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
