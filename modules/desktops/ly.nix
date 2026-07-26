{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.my.desktop.ly;
in
{
  options.my.desktop.ly.enable = lib.mkEnableOption "Ly display manager";

  config = lib.mkIf cfg.enable ({
    services.displayManager.ly.enable = true;
    # services.displayManager.defaultSession = "niri";
  });
}
