{
  config,
  configPaths,
  lib,
  ...
}:

let
  cfg = config.my.user.desktop.hyprlandConfig;
in
{
  options.my.user.desktop.hyprlandConfig.enable = lib.mkEnableOption "Hyprland user configuration";

  config = lib.mkIf cfg.enable {
    xdg.configFile = configPaths.dotfileAdapters.hyprland { };
  };
}
