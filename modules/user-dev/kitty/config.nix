{
  config,
  configPaths,
  lib,
  ...
}:
let
  cfg = config.my.user.dev.kitty;
in
{
  config = lib.mkIf cfg.enable {
    xdg.configFile = configPaths.dotfileAdapters.kitty {
      inherit (cfg) fontSize;
    };
  };
}
