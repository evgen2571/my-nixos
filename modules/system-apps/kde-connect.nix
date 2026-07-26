{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.my.system.apps.kdeConnect;
in
{
  options.my.system.apps.kdeConnect.enable = lib.mkEnableOption "KDE Connect";

  config = lib.mkIf cfg.enable ({
    programs.kdeconnect.enable = true;
  });
}
