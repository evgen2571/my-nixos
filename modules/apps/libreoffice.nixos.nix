{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.system.apps.libreoffice;
in
{
  options.my.system.apps.libreoffice.enable = lib.mkEnableOption "LibreOffice";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.libreoffice-still
    ];
  };
}
