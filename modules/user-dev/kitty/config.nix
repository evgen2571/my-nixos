{
  configPaths,
  config,
  lib,
  ...
}:

let
  cfg = config.my.user.dev.kitty;
in
{
  config = lib.mkIf cfg.enable {
    xdg.configFile."kitty/kitty.conf".source = configPaths.dev.kitty.configFile;
  };
}
