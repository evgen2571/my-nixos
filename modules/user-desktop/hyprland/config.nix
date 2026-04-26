{ config, lib,
  configPaths,
  ...
}:

let
  cfg = config.my.user.desktop.hyprlandConfig;
in
{
  options.my.user.desktop.hyprlandConfig.enable = lib.mkEnableOption "Hyprland user configuration";

  config = lib.mkIf cfg.enable (
    {
      xdg.configFile."hypr/hyprland.conf".source = configPaths.wm.hyprlandConfigDir + "/hyprland.conf";
      xdg.configFile."hypr/sub/outputs.conf".source = configPaths.wm.hyprlandConfigDir + "/sub/outputs.conf";
      xdg.configFile."hypr/sub/workspaces.conf".source = configPaths.wm.hyprlandConfigDir + "/sub/workspaces.conf";
      xdg.configFile."hypr/sub/rules.conf".source = configPaths.wm.hyprlandConfigDir + "/sub/rules.conf";
      xdg.configFile."hypr/sub/binds.conf".source = configPaths.wm.hyprlandConfigDir + "/sub/binds.conf";
      xdg.configFile."hypr/sub/layout.conf".source = configPaths.wm.hyprlandConfigDir + "/sub/layout.conf";
      xdg.configFile."hypr/sub/input.conf".source = configPaths.wm.hyprlandConfigDir + "/sub/input.conf";
      xdg.configFile."hypr/sub/startup.conf".source = configPaths.wm.hyprlandConfigDir + "/sub/startup.conf";
    }
  );
}
