{
  config,
  configPaths,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.my.user.dev.kitty;
in
{
  options.my.user.dev.kitty = {
    enable = lib.mkEnableOption "Kitty terminal";

    fontSize = lib.mkOption {
      type = lib.types.str;
      default = "17.0";
      description = "Kitty terminal font size in points.";
    };
  };

  config = lib.mkIf cfg.enable {
    xdg.configFile = configPaths.dotfileAdapters.kitty {
      inherit (cfg) fontSize;
    };

    home.packages = with pkgs; [
      kitty
    ];
  };
}
