{ config, lib, ... }:
let
  cfg = config.my.system.services.sunshine;
in
{
  options.my.system.services.sunshine.enable = lib.mkEnableOption "Sunshine";

  config = lib.mkIf cfg.enable {
    services.sunshine = {
      enable = true;
      autoStart = false;
      capSysAdmin = true;
      openFirewall = true;
    };
  };
}
