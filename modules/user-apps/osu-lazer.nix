{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.user.apps.osuLazer;
in
{
  options.my.user.apps.osuLazer.enable = lib.mkEnableOption "osu!lazer";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      osu-lazer-bin
    ];
  };
}
