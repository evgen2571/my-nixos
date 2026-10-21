{
  config,
  configPaths,
  lib,
  ...
}:

let
  cfg = config.my.user.dev.fish;
in
{
  options.my.user.dev.fish.enable = lib.mkEnableOption "Fish user configuration";

  config = lib.mkIf cfg.enable {
    xdg.configFile = configPaths.dotfileAdapters.fish { };
  };
}
