{ config, lib, ... }:
let
  cfg = config.my.server.syncthing;
  storage = config.my.server.storage;
in
{
  options.my.server.syncthing.enable = lib.mkEnableOption "server-oriented Syncthing";

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = storage.enable;
        message = "my.server.syncthing requires my.server.storage.enable to be true.";
      }
      {
        assertion = storage.device != null;
        message = ''
          my.server.syncthing requires my.server.storage.device to be set to a
          stable device path. Without a dedicated storage disk, Syncthing would
          write synchronized data to the root filesystem.

          Set my.server.storage.device to a /dev/disk/by-uuid/... path first.
        '';
      }
    ];

    users.users.syncthing = {
      isSystemUser = true;
      group = storage.dataGroup;
    };

    systemd.tmpfiles.rules = [
      "d ${storage.appDataRoot}/syncthing 2770 syncthing ${storage.dataGroup} - -"
      "d ${storage.appDataRoot}/syncthing/config 2770 syncthing ${storage.dataGroup} - -"
      "d ${storage.appDataRoot}/syncthing/database 2770 syncthing ${storage.dataGroup} - -"
    ];

    services.syncthing = {
      enable = true;

      user = "syncthing";
      group = storage.dataGroup;

      dataDir = "${storage.appDataRoot}/syncthing";
      configDir = "${storage.appDataRoot}/syncthing/config";
      databaseDir = "${storage.appDataRoot}/syncthing/database";

      guiAddress = "0.0.0.0:8384";

      openDefaultPorts = false;

      overrideDevices = false;
      overrideFolders = false;
    };

    systemd.services.syncthing = {
      unitConfig.RequiresMountsFor = [
        storage.storageRoot
      ];

      environment.GOMAXPROCS = "1";

      serviceConfig = {
        UMask = "0002";

        # CPUQuota=100% means at most one full logical CPU.
        CPUQuota = "100%";
        CPUWeight = 10;
        IOWeight = 10;

        # MemoryHigh throttles first; MemoryMax is the final safety rail.
        MemoryHigh = "40%";
        MemoryMax = "50%";
        TasksMax = 256;
      };
    };

    networking.firewall.interfaces.tailscale0 = {
      allowedTCPPorts = [
        8384
        22000
      ];
      allowedUDPPorts = [
        22000
      ];
    };
  };
}
