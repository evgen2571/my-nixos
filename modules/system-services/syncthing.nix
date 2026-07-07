{ config, lib, ... }:

let
  cfg = config.my.system.services.syncthing;
  primaryUser = config.my.primaryUser.name;
in
{
  options.my.system.services.syncthing.enable = lib.mkEnableOption "Syncthing";

  config = lib.mkIf cfg.enable {
    services.syncthing = {
      enable = true;
      user = primaryUser;
      group = "users";
      dataDir = "/home/${primaryUser}";
      configDir = "/home/${primaryUser}/.config/syncthing";
      databaseDir = "/home/${primaryUser}/.local/state/syncthing";
      openDefaultPorts = true;
    };
  };
}
