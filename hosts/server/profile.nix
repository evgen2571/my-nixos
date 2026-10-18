{ config, ... }:

{
  my = {
    server = {
      base.enable = true;

      ssh = {
        enable = true;
        port = 22;
        openOnLan = false;
      };

      storage = {
        enable = true;

        dataGroup = "server-data";
        dataGroupId = null;

        composeRoot = "/srv/compose";
        appDataRoot = "/srv/appdata";
        storageRoot = "/srv/storage";
        sharedRoot = "/srv/shared";
        backupsRoot = "/srv/backups";
        secretsRoot = "/srv/secrets";

        device = "/dev/disk/by-uuid/ff9ba794-22fe-4906-a516-a3b438200259";
        fsType = "ext4";

        mountOptions = [
          "defaults"
          "x-systemd.device-timeout=30s"
        ];
      };

      dockerHost.enable = true;
      syncthing.enable = true;
    };

    system.services.networkNamespaces = {
      enable = true;
      namespaces.vpn = {
        enable = true;
        server = "free-de";
        bootstrapTokenFile = (
          config.sops.secrets.hide-me-bootstrap-token.path or "/run/my-nixos-unavailable/bootstrap"
        );
        shared = {
          privateKeyFile = (
            config.sops.secrets.vpn-wireguard-private-key.path or "/run/my-nixos-unavailable/wireguard"
          );
          role = "gateway";
        };
      };
    };

    system.services.tailscale = {
      enable = true;
      openFirewall = true;
    };
  };

  my.primaryUser.home.settings.my.user.dev.git.enable = true;
}
