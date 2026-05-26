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
      brightnessctl
      playerctl
      polkit_gnome
      wireplumber
    ];

    services.udev.packages = with pkgs; [
      brightnessctl
    ];

    programs.niri = {
      enable = true;
      # Niri's upstream/NixOS portal setup already wires GNOME for screencast
      # and GTK as the fallback. Keep GTK for file pickers so we do not depend
      # on Nautilus just to use xdg-desktop-portal-gnome.
      useNautilus = false;
    };
  };
}
