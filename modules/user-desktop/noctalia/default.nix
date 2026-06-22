{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.my.user.desktop.noctalia;
in
{
  imports = [
    inputs.noctalia.homeModules.default
    ./config.nix
  ];

  options.my.user.desktop.noctalia.enable = lib.mkEnableOption "Noctalia shell";

  config = lib.mkIf cfg.enable {
    programs.noctalia = {
      enable = true;
      systemd.enable = true;
    };
  };
}
