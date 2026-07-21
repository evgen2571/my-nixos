{ config, lib, ... }:

let
  cfg = config.my.system.services.lanMouse;
in
{
  options.my.system.services.lanMouse.enable = lib.mkEnableOption "Lan Mouse firewall access";

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedUDPPorts = [ 4242 ];
  };
}