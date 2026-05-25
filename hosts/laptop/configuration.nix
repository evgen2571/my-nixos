{ modulePaths, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./profile.nix
    modulePaths.system.common
    modulePaths.system.user
  ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "nixos-lp";

  services.libinput.enable = true;

  xdg.portal = {
    enable = true;

    extraPortals = with pkgs; [
      xdg-desktop-portal-gnome
      xdg-desktop-portal-gtk
    ];

    config = {
      common = {
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

      niri = {
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
  };

  services.fprintd.enable = true;
  security.pam.services.ly.fprintAuth = true;
  security.pam.services.sudo.fprintAuth = false;

  my.system.user = {
    enable = true;
    name = "operator";
    description = "Operator";
    shell = pkgs.fish;
    extraGroups = [
      "networkmanager"
      "wheel"
      "input"
      "git"
    ];
  };

  swapDevices = [
    {
      device = "/swapfile";
      size = 16384;
    }
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  system.stateVersion = "25.11";
}
