{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.desktop.umbriel;
in
{
  imports = [ inputs.umbriel.nixosModules.default ];

  options.my.desktop.umbriel.enable = lib.mkEnableOption "Umbriel desktop session";

  config = lib.mkIf cfg.enable {
    programs.umbriel.enable = true;
    qt = {
      enable = true;
      platformTheme = "kde";
    };

    security.polkit.enable = true;
    security.rtkit.enable = lib.mkDefault true;
    services.gnome.gnome-keyring.enable = true;
    programs.seahorse.enable = true;

    environment.systemPackages = with pkgs; [
      brightnessctl
      playerctl
      polkit_gnome
    ];
    services.udev.packages = [ pkgs.brightnessctl ];

    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      ELECTRON_OZONE_PLATFORM_HINT = "wayland";
    };

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

    xdg.portal = {
      enable = true;
      xdgOpenUsePortal = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
        kdePackages.xdg-desktop-portal-kde
      ];
      config.umbriel = {
        default = [
          "umbriel"
          "gtk"
        ];
        "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
        "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
      };
    };
  };
}
