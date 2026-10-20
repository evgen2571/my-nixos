{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.user.apps.obsidian;
in
{
  options.my.user.apps.obsidian.enable = lib.mkEnableOption "Obsidian";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      obsidian
    ];
  };
}
