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
    qt = {
      enable = true;
      platformTheme = "kde";
    };

    services.xserver.enable = true;
    programs.xwayland.enable = true;

    security.polkit.enable = true;
    security.rtkit.enable = lib.mkDefault true;

    services.gnome.gnome-keyring.enable = true;
    # Inspect and change the Login keyring password if it differs from PAM.
    programs.seahorse.enable = true;

    environment.systemPackages = with pkgs; [
      brightnessctl
      playerctl
      polkit_gnome
      # Niri manages satellite on demand and publishes its allocated DISPLAY.
      xwayland-satellite

      pipewire
      wireplumber

      xdg-desktop-portal
      xdg-desktop-portal-gnome
      xdg-desktop-portal-gtk
    ];

    systemd.user.services.polkit-gnome-authentication-agent-1 = {
      description = "Polkit GNOME Authentication Agent";

      wantedBy = [ "graphical-session.target" ];
      wants = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];

      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
      };
    };

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
        # The KDE Qt platform theme calls this chooser directly.
        kdePackages.xdg-desktop-portal-kde
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

    # Portals started before Niri publishes its Wayland session cannot share
    # the screen in OBS or Chromium. Restart them once the session is ready.
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
