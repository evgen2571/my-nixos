{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.user.apps.krita;
in
{
  options.my.user.apps.krita.enable = lib.mkEnableOption "Krita";

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.krita
    ];
  };
}
