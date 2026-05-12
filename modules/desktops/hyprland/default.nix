{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.desktop.hyprland;
  optionalPackage = name: lib.optional (builtins.hasAttr name pkgs) (builtins.getAttr name pkgs);
in
{
  options.my.desktop.hyprland.enable = lib.mkEnableOption "Hyprland desktop session";

  config = lib.mkIf cfg.enable {
    services.xserver.enable = true;
    programs.xwayland.enable = true;

    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
    };

    xdg.portal = {
      enable = true;
      extraPortals =
        optionalPackage "xdg-desktop-portal-gtk"
        ++ optionalPackage "xdg-desktop-portal-hyprland"
        ++ optionalPackage "xdg-desktop-portal-kde";
    };

    security.polkit.enable = true;
    services.gnome.gnome-keyring.enable = true;

    environment.systemPackages =
      optionalPackage "xdg-desktop-portal"
      ++ optionalPackage "xdg-desktop-portal-gtk"
      ++ optionalPackage "xdg-desktop-portal-hyprland";
  };
}
