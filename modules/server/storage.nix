{ config, lib, ... }:

let
  cfg = config.my.server.storage;
  primaryUser = config.my.primaryUser.name;
in
{
  options.my.server.storage = {
    enable = lib.mkEnableOption "server storage layout";

    dataGroup = lib.mkOption {
      type = lib.types.str;
      default = "server-data";
      description = "Group for server data access.";
    };

    dataGroupId = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      default = null;
      description = "GID for server-data group. Null lets NixOS allocate.";
    };

    composeRoot = lib.mkOption {
      type = lib.types.str;
      default = "/srv/compose";
      description = "Root directory for Docker Compose projects.";
    };

    appDataRoot = lib.mkOption {
      type = lib.types.str;
      default = "/srv/appdata";
      description = "Root directory for persistent application data.";
    };

    storageRoot = lib.mkOption {
      type = lib.types.str;
      default = "/srv/storage";
      description = "Root directory for general storage (intended mount point).";
    };

    sharedRoot = lib.mkOption {
      type = lib.types.str;
      default = "/srv/shared";
      description = "Root directory for shared data.";
    };

    backupsRoot = lib.mkOption {
      type = lib.types.str;
      default = "/srv/backups";
      description = "Root directory for backups.";
    };

    secretsRoot = lib.mkOption {
      type = lib.types.str;
      default = "/srv/secrets";
      description = "Root directory for runtime secrets (provisioned separately).";
    };

    device = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Stable device path for the storage filesystem e.g. /dev/disk/by-uuid/...";
    };

    fsType = lib.mkOption {
      type = lib.types.str;
      default = "ext4";
      description = "Filesystem type for the storage device.";
    };

    mountOptions = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "defaults"
        "x-systemd.device-timeout=30s"
      ];
      description = "Mount options for the storage device.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = lib.optional (cfg.device != null) {
      assertion = lib.any (
        prefix:
        lib.hasPrefix prefix cfg.device
        && cfg.device != prefix
      ) [
        "/dev/disk/by-uuid/"
        "/dev/disk/by-label/"
        "/dev/disk/by-id/"
      ];
      message = ''
        my.server.storage.device must use a stable path under one of:

          /dev/disk/by-uuid/
          /dev/disk/by-label/
          /dev/disk/by-id/

        Current value: ${cfg.device}

        Find stable identifiers with:
          lsblk -f
          sudo blkid

        Do not use unstable names such as /dev/sda1 or /dev/sdb1.
      '';
    };

    users.groups.${cfg.dataGroup} = {
      name = cfg.dataGroup;
      gid = cfg.dataGroupId;
    };

    users.users.${primaryUser}.extraGroups = [
      cfg.dataGroup
    ];

    systemd.tmpfiles.rules = [
      "d ${cfg.composeRoot} 0750 ${primaryUser} ${cfg.dataGroup} - -"
      "d ${cfg.appDataRoot} 2770 ${primaryUser} ${cfg.dataGroup} - -"
      "d ${cfg.storageRoot} 2770 root ${cfg.dataGroup} - -"
      "d ${cfg.sharedRoot} 2770 ${primaryUser} ${cfg.dataGroup} - -"
      "d ${cfg.backupsRoot} 2770 ${primaryUser} ${cfg.dataGroup} - -"
      "d ${cfg.secretsRoot} 0700 root root - -"
    ];

    fileSystems = lib.mkIf (cfg.device != null) {
      ${cfg.storageRoot} = {
        device = cfg.device;
        fsType = cfg.fsType;
        options = cfg.mountOptions;
      };
    };
  };
}
