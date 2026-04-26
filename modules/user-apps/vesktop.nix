{ config, lib,  pkgs, ... }:

let
  cfg = config.my.user.apps.vesktop;
in
{
  options.my.user.apps.vesktop.enable = lib.mkEnableOption "Vesktop";

  config = lib.mkIf cfg.enable (
    {
      home.packages = with pkgs; [
        vesktop
      ];
    }
  );
}
