{ config, ... }:

{
  imports = [
    ../common/desktop.nix
  ];

  my = {
    desktop = {
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
        waydroid.enable = true;
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

              address = "10.77.0.3/24";
              address6 = "fd77::3/64";
            };
          };
        };

        virtualization.enable = true;
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

    desktop = {
      niriConfig = {
        workspaceProfile = "laptop";
      };

      noctalia = {
        profile = "laptop";
      };
    };

    dev = {
      pycharm.enable = false;
      kitty.fontSize = "13.0";

      languages = {
        cpp.enable = true;
        java.enable = true;
        python.enable = true;
        rust.enable = true;
      };
    };
  };
}
