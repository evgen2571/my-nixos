{ config, lib,
  configPaths,
  pkgs,
  ...
}:

let
  cfg = config.my.user.dev.starship;
in
{
  options.my.user.dev.starship = {
    enable = lib.mkEnableOption "Starship prompt";

    configFile = lib.mkOption {
      type = lib.types.path;
      default = configPaths.dev.starship.configFile;
      description = "Starship config file to symlink into ~/.config/starship.toml.";
    };
  };

  config = lib.mkIf cfg.enable (
    {
      home.packages = with pkgs; [
        starship
      ];

      xdg.configFile."starship.toml".source = cfg.configFile;
    }
  );
}
