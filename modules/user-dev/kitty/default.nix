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
  imports = [
    ./config.nix
  ];

  options.my.user.dev.kitty = {
    enable = lib.mkEnableOption "Kitty terminal";

    configFile = lib.mkOption {
      type = lib.types.path;
      default = configPaths.dev.kitty.configFile;
      description = "Kitty config file to symlink into ~/.config/kitty/kitty.conf.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      kitty
    ];
  };
}
