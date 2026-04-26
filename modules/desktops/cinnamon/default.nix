{ lib,  config, pkgs, ... }:

let
  cfg = config.my.desktop.cinnamon;
in
{
  options.my.desktop.cinnamon.enable = lib.mkEnableOption "Cinnamon desktop environment";

  config = lib.mkIf cfg.enable (
    {
      services.xserver.desktopManager.cinnamon.enable = true;
    }
  );
}
