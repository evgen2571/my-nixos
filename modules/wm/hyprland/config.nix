{ ... }:

{
  xdg.configFile."hypr/hyprland.conf".source = ./config/hyprland.conf;
  xdg.configFile."hypr/sub/outputs.conf".source = ./config/sub/outputs.conf;
  xdg.configFile."hypr/sub/workspaces.conf".source = ./config/sub/workspaces.conf;
  xdg.configFile."hypr/sub/rules.conf".source = ./config/sub/rules.conf;
  xdg.configFile."hypr/sub/binds.conf".source = ./config/sub/binds.conf;
  xdg.configFile."hypr/sub/layout.conf".source = ./config/sub/layout.conf;
  xdg.configFile."hypr/sub/input.conf".source = ./config/sub/input.conf;
  xdg.configFile."hypr/sub/startup.conf".source = ./config/sub/startup.conf;
}
