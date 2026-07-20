{
  config,
  configPaths,
  lib,
  ...
}:

let
  cfg = config.my.user.desktop.kdeplasmaConfig;
in
{
  options.my.user.desktop.kdeplasmaConfig.enable =
    lib.mkEnableOption "KDE Plasma user configuration";

  config = lib.mkIf cfg.enable {
    xdg.configFile = configPaths.dotfileAdapters.kdeplasma { };
  };
}
