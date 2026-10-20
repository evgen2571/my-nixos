{
  config,
  configPaths,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.user.dev.starship;
in
{
  options.my.user.dev.starship.enable = lib.mkEnableOption "Starship prompt";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      starship
    ];

    xdg.configFile = configPaths.dotfileAdapters.starship { };
  };
}
