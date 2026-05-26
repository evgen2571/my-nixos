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
      # Keep GTK file pickers instead of pulling in Nautilus for
      # xdg-desktop-portal-gnome's FileChooser implementation.
      useNautilus = false;
    };

    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
      ];

      # programs.niri.useNautilus = false adds an explicit niri portal config
      # for FileChooser. Explicit xdg.portal.config entries take precedence over
      # Niri's packaged niri-portals.conf, so restate the full Niri preference
      # set here; otherwise Electron/WebRTC can see no ScreenCast portal at all.
      config.niri = {
        default = [
          "gnome"
          "gtk"
        ];
        "org.freedesktop.impl.portal.Access" = "gtk";
        "org.freedesktop.impl.portal.FileChooser" = "gtk";
        "org.freedesktop.impl.portal.Notification" = "gtk";
        "org.freedesktop.impl.portal.ScreenCast" = "gnome";
        "org.freedesktop.impl.portal.Screenshot" = "gnome";
        "org.freedesktop.impl.portal.Secret" = "gnome-keyring";
      };
    };
  };
}
