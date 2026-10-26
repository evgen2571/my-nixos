{
  config,
  configPaths,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.user.desktop.umbrielConfig;
in
{
  options.my.user.desktop.umbrielConfig.enable = lib.mkEnableOption "Umbriel user configuration";

  config = lib.mkIf cfg.enable {
    # Own leaves so Noctalia can write its generated theme beside them.
    xdg.configFile =
      lib.genAttrs
        (map (name: "umbriel/${name}") [
          "config.toml"
          "binds.toml"
          "rules.toml"
        ])
        (name: {
          source = configPaths.wm.umbrielConfigDir + "/${lib.removePrefix "umbriel/" name}";
        })
      // {
        "umbriel/scratchpads.toml".source = pkgs.replaceVars (
          configPaths.wm.umbrielConfigDir + "/scratchpads.toml"
        ) { musicPlayer = if config.my.user.apps.sonora.enable then "sonora" else "pear-desktop"; };
        "umbriel/scripts/focus-or-launch" = {
          source = configPaths.wm.umbrielConfigDir + "/scripts/focus-or-launch";
          executable = true;
        };
      };

    home.packages = [ pkgs.python3 ];

    programs.noctalia.settings.theme.templates.builtin_ids =
      lib.mkIf config.my.user.desktop.noctalia.enable
        [
          "cava"
          "gtk3"
          "gtk4"
          "kcolorscheme"
          "kitty"
          "umbriel"
        ];
  };
}
