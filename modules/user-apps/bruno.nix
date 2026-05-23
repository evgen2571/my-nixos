{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.user.apps.bruno;
in
{
  options.my.user.apps.bruno.enable = lib.mkEnableOption "Bruno API client";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      bruno
    ];
  };
}
