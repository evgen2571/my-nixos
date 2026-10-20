{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.server.dockerHost;
  storage = config.my.server.storage;
in
{
  options.my.server.dockerHost.enable = lib.mkEnableOption "production-oriented Docker host";

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = storage.enable;
        message = "my.server.dockerHost requires my.server.storage.enable to be true.";
      }
    ];

    virtualisation.docker = {
      enable = true;
      enableOnBoot = true;

      autoPrune = {
        enable = true;
        dates = "weekly";
        flags = [
          "--filter=until=168h"
        ];
      };

      daemon.settings = {
        live-restore = true;
        log-driver = "json-file";

        log-opts = {
          max-size = "10m";
          max-file = "5";
        };
      };
    };

    users.users.${config.my.primaryUser.name}.extraGroups = [
      "docker"
    ];

    environment.systemPackages = with pkgs; [
      docker-compose
      lazydocker
    ];
  };
}
