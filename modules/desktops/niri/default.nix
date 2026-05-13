{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.my.desktop.niri;
in
{
  options.my.desktop.niri.enable = lib.mkEnableOption "Niri desktop session";

  config = lib.mkIf cfg.enable {
    services.xserver.enable = true;
    programs.xwayland.enable = true;

    security.polkit.enable = true;
    services.gnome.gnome-keyring.enable = true;

    environment.systemPackages = with pkgs; [
      polkit_gnome
    ];

    programs.niri.enable = true;
  };
}
