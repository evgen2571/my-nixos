{
  config,
  configPaths,
  lib,
  ...
}:

let
  cfg = config.my.user.dev.fish;
in
{
  imports = [
    ./config.nix
  ];

  options.my.user.dev.fish = {
    enable = lib.mkEnableOption "Fish user configuration";

    configDir = lib.mkOption {
      type = lib.types.path;
      default = configPaths.dev.fish.configDir;
      description = "Fish config directory to symlink into ~/.config/fish.";
    };
  };
}
