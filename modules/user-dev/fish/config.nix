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
  config = lib.mkIf cfg.enable {
    xdg.configFile = configPaths.dotfileAdapters.fish { };
  };
}
