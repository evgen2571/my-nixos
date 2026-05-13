{ config, lib, ... }:

let
  cfg = config.my.hardware.bluetooth;
in
{
  options.my.hardware.bluetooth = {
    enable = lib.mkEnableOption "Bluetooth hardware support";

    powerOnBoot = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to power on the Bluetooth adapter automatically at boot.";
    };
  };

  config = lib.mkIf cfg.enable {
    hardware.bluetooth = {
      enable = true;
      inherit (cfg) powerOnBoot;
    };
  };
}
