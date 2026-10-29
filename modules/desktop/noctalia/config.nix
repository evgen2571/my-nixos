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
      lib.recursiveUpdate
        {
          shell = {
            avatar_path = "${config.home.homeDirectory}/.face";
            screenshot.directory = "${config.xdg.userDirs.pictures}/screenshots";
          };

          wallpaper.directory = "${config.xdg.userDirs.pictures}/wallpapers";

          theme.templates.user = {
            nvim-base16.enabled = lib.attrByPath [ "my" "user" "dev" "neovim" "enable" ] false config;
            niri-layout.enabled = lib.attrByPath [ "my" "user" "desktop" "niriConfig" "enable" ] false config;
            niri-dropdown.enabled = lib.attrByPath [ "my" "user" "desktop" "niriConfig" "enable" ] false config;
          };
        }
        (
          lib.recursiveUpdate (builtins.fromTOML (builtins.readFile cfg.configFile)) (
            lib.optionalAttrs (cfg.profile == "pc") (
              builtins.fromTOML (builtins.readFile (configPaths.wm.noctaliaConfigDir + "/widgets-pc.toml"))
            )
          )
        )
    );

    xdg.configFile = {
      "noctalia/templates/niri-layout.kdl".source =
        configPaths.wm.noctaliaConfigDir + "/templates/niri-layout.kdl";

      "noctalia/templates/niri-dropdown.kdl".source =
        configPaths.wm.noctaliaConfigDir + "/templates/niri-dropdown.kdl";
    };
  };
}
