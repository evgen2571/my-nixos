{ ... }:

{
  my = {
    server = {
      base.enable = true;

      ssh = {
        enable = true;
        port = 22;
        openOnLan = true;
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

        device = null;
        fsType = "ext4";

        mountOptions = [
          "defaults"
          "x-systemd.device-timeout=30s"
        ];
      };

      dockerHost.enable = true;

      # Enable only after storage.device has been set to a real
      # /dev/disk/by-* path for the server's data disk.
      syncthing.enable = false;
    };

    system.services.tailscale.enable = true;
  };

  my.primaryUser.home.settings.my.user.dev.git.enable = true;

  services.hermes-agent = {
    enable = true;
    addToSystemPackages = false;
    environmentFiles = [ "/var/lib/hermes/env" ];

    settings = {
      model.default = "openai/gpt-5.4";
      toolsets = [ "all" ];
      terminal = {
        backend = "local";
        timeout = 180;
      };
    };
  };

  my.system.services.vpnbookWireguardFailover = {
    enable = true;
    configDir = "/etc/wireguard/vpnbook";
    stateDir = "/var/lib/vpnbook-wireguard";
    interfaceName = "vpnbook0";
    checkInterval = "1min";
  };
}
