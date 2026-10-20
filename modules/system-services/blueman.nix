{ config, lib, ... }:
let
  cfg = config.my.system.services.blueman;
in
{
  options.my.system.services.blueman.enable = lib.mkEnableOption "Blueman Bluetooth manager";

  config = lib.mkIf cfg.enable {
    services.blueman.enable = true;
  };
}
