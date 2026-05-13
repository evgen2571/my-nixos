{ config, lib,  inputs, pkgs, ... }:

let
  cfg = config.my.system.services.bluetooth;
in
{
  options.my.system.services.bluetooth.enable = lib.mkEnableOption "Bluetooth";

  config = lib.mkIf cfg.enable (
  {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = false;
    };

	services.blueman.enable = true;
  }
  );
}
