{ lib,
  configPaths,
  config,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.my.user.desktop.niriConfig;
in
{
  options.my.user.desktop.niriConfig = {
    enable = lib.mkEnableOption "Niri user configuration";

    workspacesFile = lib.mkOption {
      type = lib.types.str;
      default = "workspaces.kdl";
      description = "Host-specific Niri workspace file from config/niri/sub.";
    };
  };

  config = lib.mkIf cfg.enable (
    {
      xdg.configFile."niri/sub/outputs.kdl".source = configPaths.wm.niriConfigDir + "/sub/outputs.kdl";
      xdg.configFile."niri/sub/workspaces.kdl".source = configPaths.wm.niriConfigDir + "/sub/${cfg.workspacesFile}";
      xdg.configFile."niri/sub/rules.kdl".source = configPaths.wm.niriConfigDir + "/sub/rules.kdl";
      xdg.configFile."niri/sub/binds.kdl".source = configPaths.wm.niriConfigDir + "/sub/binds.kdl";
      xdg.configFile."niri/sub/layout.kdl".source = configPaths.wm.niriConfigDir + "/sub/layout.kdl";
      xdg.configFile."niri/sub/input.kdl".source = configPaths.wm.niriConfigDir + "/sub/input.kdl";
      xdg.configFile."niri/sub/startup.kdl".source = configPaths.wm.niriConfigDir + "/sub/startup.kdl";

      xdg.configFile."niri/config.kdl".source = configPaths.wm.niriConfigDir + "/config.kdl";
    }
  );
}
