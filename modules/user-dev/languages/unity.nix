{ config, lib, pkgs, ... }:

let
  cfg = config.my.user.dev.languages.unity;
in
{
  options.my.user.dev.languages.unity.enable = lib.mkEnableOption "Unity game development";

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.unityhub
    ];
  };
}
