{
  config,
  pkgs,
  inputs,
  ...
}:

{
  xdg.configFile."niri/sub/outputs.kdl".source = ./config/sub/outputs.kdl;
  xdg.configFile."niri/sub/workspaces.kdl".source = ./config/sub/workspaces.kdl;
  xdg.configFile."niri/sub/rules.kdl".source = ./config/sub/rules.kdl;
  xdg.configFile."niri/sub/binds.kdl".source = ./config/sub/binds.kdl;
  xdg.configFile."niri/sub/layout.kdl".source = ./config/sub/layout.kdl;
  xdg.configFile."niri/sub/input.kdl".source = ./config/sub/input.kdl;
  xdg.configFile."niri/sub/startup.kdl".source = ./config/sub/startup.kdl;

  xdg.configFile."niri/config.kdl".source = ./config/config.kdl;
}
