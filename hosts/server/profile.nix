{ ... }:

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

        device = "/dev/disk/by-label/MY-NIXOS-SERVER-STORAGE-REPLACE-ME";
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
        shared = {
          role = "gateway";
          peers = [
            {
              publicKeyFile = "/var/lib/netns-vpn-shared/pc.pub";
              allowedIPs = [
                "10.77.0.2/32"
                "fd77::2/128"
              ];
            }
            {
              publicKeyFile = "/var/lib/netns-vpn-shared/laptop.pub";
              allowedIPs = [
                "10.77.0.3/32"
                "fd77::3/128"
              ];
            }
          ];
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
