{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.my.desktop.niri;
in
{
  options.my.desktop.niri.enable = lib.mkEnableOption "Niri desktop session";

  config = lib.mkIf cfg.enable {
    services.xserver.enable = true;
    programs.xwayland.enable = true;

    programs.niri.enable = true;
  };
}
