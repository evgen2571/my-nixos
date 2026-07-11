{
  config,
  lib,
  pkgs,
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
    security.rtkit.enable = lib.mkDefault true;

    services.gnome.gnome-keyring.enable = true;

    services.pipewire = {
      enable = lib.mkDefault true;
      alsa.enable = lib.mkDefault true;
      alsa.support32Bit = lib.mkDefault true;
      pulse.enable = lib.mkDefault true;
      wireplumber.enable = lib.mkDefault true;
    };

    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      ELECTRON_OZONE_PLATFORM_HINT = "wayland";
    };

    environment.systemPackages = with pkgs; [
      brightnessctl
      playerctl
      polkit_gnome

      pipewire
      wireplumber

      xdg-desktop-portal
      xdg-desktop-portal-gnome
      xdg-desktop-portal-gtk
    ];

    services.udev.packages = with pkgs; [
      brightnessctl
    ];

    programs.niri = {
      enable = true;

      # Keep GTK file picker instead of pulling in Nautilus.
      useNautilus = false;
    };

    xdg.portal = {
      enable = true;
      xdgOpenUsePortal = true;

      extraPortals = with pkgs; [
        xdg-desktop-portal-gnome
        xdg-desktop-portal-gtk
      ];

      config.niri = {
        default = [
          "gnome"
          "gtk"
        ];

        "org.freedesktop.impl.portal.Access" = [ "gtk" ];
        "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
        "org.freedesktop.impl.portal.Notification" = [ "gtk" ];
        "org.freedesktop.impl.portal.ScreenCast" = [ "gnome" ];
        "org.freedesktop.impl.portal.Screenshot" = [ "gnome" ];
        "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
      };
    };

    # Portal services can be D-Bus activated before Niri has finished
    # publishing the Wayland session. In that state OBS and Chromium-based
    # apps see a portal, but the ScreenCast session cannot be subscribed to.
    # Re-run the same initialization that fixes it manually, once the desktop
    # session is fully up.
    systemd.user.services.niri-portal-init = {
      description = "Initialize Niri screen-sharing portals";
      wantedBy = [ "graphical-session.target" ];
      wants = [
        "xdg-desktop-portal.service"
        "xdg-desktop-portal-gnome.service"
      ];
      after = [
        "graphical-session.target"
        "xdg-desktop-portal.service"
        "xdg-desktop-portal-gnome.service"
      ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "niri-portal-init" ''
          set -eu
          ${pkgs.systemd}/bin/systemctl --user restart \
            xdg-desktop-portal.service \
            xdg-desktop-portal-gnome.service
        '';
      };
    };
  };
}
