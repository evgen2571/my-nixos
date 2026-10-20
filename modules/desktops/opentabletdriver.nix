{
  config,
  lib,
  ...
}:

let
  cfg = config.my.desktop.opentabletdriver;
in
{
  options.my.desktop.opentabletdriver.enable = lib.mkEnableOption "OpenTabletDriver support";

  config = lib.mkIf cfg.enable {
    hardware.opentabletdriver.enable = true;

    # Required by OpenTabletDriver
    hardware.uinput.enable = true;
    boot.kernelModules = [ "uinput" ];
  };
}
