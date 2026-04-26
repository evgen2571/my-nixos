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

  options.my.user.dev.kitty.enable = lib.mkEnableOption "Kitty terminal";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      kitty
    ];
  };
}
