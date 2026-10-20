{
  config,
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

    fontSize = lib.mkOption {
      type = lib.types.str;
      default = "17.0";
      description = "Kitty terminal font size in points.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      kitty
    ];
  };
}
