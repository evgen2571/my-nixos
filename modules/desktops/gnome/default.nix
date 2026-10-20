{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.my.desktop.gnome;
in
{
  options.my.desktop.gnome.enable = lib.mkEnableOption "GNOME desktop environment";

  config = lib.mkIf cfg.enable {
    services = {
      desktopManager.gnome.enable = true;
      displayManager.gdm.enable = false;
      gnome = {
        core-apps.enable = false;
        core-developer-tools.enable = false;
        games.enable = false;
      };

    };

    # Extra cleanup for packages that may still appear depending on nixpkgs version.
    environment.gnome.excludePackages = with pkgs; [
      gnome-tour
      gnome-user-docs

      # apps / utilities
      epiphany
      geary
      gnome-calendar
      gnome-characters
      gnome-clocks
      gnome-connections
      gnome-console
      gnome-contacts
      gnome-font-viewer
      gnome-logs
      gnome-maps
      gnome-music
      gnome-photos
      gnome-system-monitor
      gnome-text-editor
      gnome-weather

      # file/document/media tools
      nautilus
      evince
      file-roller
      loupe
      simple-scan
      snapshot
      totem
      yelp
    ];
  };
}
