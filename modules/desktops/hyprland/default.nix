{ config, lib, ... }:

let
  cfg = config.my.desktop.hyprland;
in
{
  options.my.desktop.hyprland.enable = lib.mkEnableOption "Hyprland desktop session";

  config = lib.mkIf cfg.enable {
    services.xserver.enable = true;
    programs.xwayland.enable = true;

    programs.hyprland = {
      enable = true;
    };
  };
}
