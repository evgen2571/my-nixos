{ config, lib, ... }:

let
  cfg = config.my.system.services.syncthing;
in
{
  options.my.system.services.syncthing.enable = lib.mkEnableOption "Syncthing";

  config = lib.mkIf cfg.enable {
    services.syncthing = {
      enable = true;
      openDefaultPorts = true;
    };
  };
}
