{
  configPaths,
  config,
  lib,
  ...
}:
let
  cfg = config.my.user.desktop.noctalia;
in
{
  config = lib.mkIf cfg.enable {
    programs.noctalia.settings = lib.mapAttrsRecursive (_: lib.mkDefault) (
      lib.recursiveUpdate {
        shell = {
          avatar_path = "${config.home.homeDirectory}/.face";
          screenshot.directory = "${config.home.homeDirectory}/Pictures/Screenshots";
        };
        wallpaper.directory = "${config.home.homeDirectory}/Pictures/Wallpapers";
      } (builtins.fromTOML (builtins.readFile cfg.configFile))
    );

    xdg.configFile = {
      "noctalia/bar-common.toml".source = configPaths.wm.noctaliaConfigDir + "/bar-common.toml";
      "noctalia/bar.toml".source = configPaths.wm.noctaliaConfigDir + "/bar-${cfg.profile}.toml";
      "noctalia/user-templates.toml".source = configPaths.wm.noctaliaConfigDir + "/user-templates.toml";
      "noctalia/templates/niri-dropdown.kdl".source =
        configPaths.wm.noctaliaConfigDir + "/templates/niri-dropdown.kdl";
      "noctalia/widgets-common.toml".source = configPaths.wm.noctaliaConfigDir + "/widgets-common.toml";
      "noctalia/widgets.toml".source = configPaths.wm.noctaliaConfigDir + "/widgets-${cfg.profile}.toml";
    };
  };
}
