{ lib, config, ... }:

let
  cfg = config.my.desktop.xserver;
in
{
  options.my.desktop.xserver.enable = lib.mkEnableOption "X server and XWayland support";

  config = lib.mkIf cfg.enable {
    services.xserver.enable = true;
    programs.xwayland.enable = true;
  };
}
