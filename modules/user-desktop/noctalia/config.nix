{
  configPaths,
  config,
  lib,
  ...
}:

let
  cfg = config.my.user.desktop.noctalia;
  configDir = ".config/noctalia";
in
{
  config = lib.mkIf cfg.enable {
    programs.noctalia.settings = cfg.configFile;

    xdg.configFile = {
      "noctalia/bar-common.toml".source = configPaths.wm.noctaliaConfigDir + "/bar-common.toml";
      "noctalia/bar.toml".source = configPaths.wm.noctaliaConfigDir + "/bar-${cfg.profile}.toml";
      "noctalia/user-templates.toml".source =
        configPaths.wm.noctaliaConfigDir + "/user-templates.toml";
      "noctalia/widgets-common.toml".source =
        configPaths.wm.noctaliaConfigDir + "/widgets-common.toml";
      "noctalia/widgets.toml".source =
        configPaths.wm.noctaliaConfigDir + "/widgets-${cfg.profile}.toml";
    };

    # Legacy Noctalia v4 config installer, kept for rollback/reference.
    # Enable with:
    #   my.user.desktop.noctalia.legacyConfig.enable = true;
    #
    # Old active setup before v5 moved to TOML:
    #   install -D -m 644 config/noctalia/settings.json "$HOME/.config/noctalia/settings.json"
    #   install -D -m 644 config/noctalia/plugins.json "$HOME/.config/noctalia/plugins.json"
    #   install -D -m 644 config/noctalia/user-templates.toml "$HOME/.config/noctalia/user-templates.toml"
    home.activation.installLegacyNoctaliaConfig = lib.mkIf cfg.legacyConfig.enable (
      config.lib.dag.entryAfter [ "writeBoundary" ] ''
        install -D -m 644 ${
          configPaths.wm.noctaliaConfigDir + "/v4/settings.json"
        } "$HOME/${configDir}/settings.json"
        install -D -m 644 ${
          configPaths.wm.noctaliaConfigDir + "/v4/plugins.json"
        } "$HOME/${configDir}/plugins.json"
        install -D -m 644 ${
          configPaths.wm.noctaliaConfigDir + "/v4/user-templates.toml"
        } "$HOME/${configDir}/user-templates.toml"
      ''
    );
  };
}
