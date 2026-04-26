{
  configPaths,
  config,
  pkgs,
  inputs,
  ...
}:

{
  xdg.configFile."niri/sub/outputs.kdl".source = configPaths.wm.niriConfigDir + "/sub/outputs.kdl";
  xdg.configFile."niri/sub/workspaces.kdl".source = configPaths.wm.niriConfigDir + "/sub/workspaces.kdl";
  xdg.configFile."niri/sub/rules.kdl".source = configPaths.wm.niriConfigDir + "/sub/rules.kdl";
  xdg.configFile."niri/sub/binds.kdl".source = configPaths.wm.niriConfigDir + "/sub/binds.kdl";
  xdg.configFile."niri/sub/layout.kdl".source = configPaths.wm.niriConfigDir + "/sub/layout.kdl";
  xdg.configFile."niri/sub/input.kdl".source = configPaths.wm.niriConfigDir + "/sub/input.kdl";
  xdg.configFile."niri/sub/startup.kdl".source = configPaths.wm.niriConfigDir + "/sub/startup.kdl";

  xdg.configFile."niri/config.kdl".source = configPaths.wm.niriConfigDir + "/config.kdl";
}
