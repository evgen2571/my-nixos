{ pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./profile.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos-pc";
  networking.networkmanager = {
    enable = true;
    plugins = with pkgs; [
      networkmanager-openvpn
    ];
  };

  programs.nm-applet.enable = true;

  time.timeZone = "Europe/Minsk";
  i18n.defaultLocale = "en_US.UTF-8";

  services.xserver = {
    enable = true;
    xkb = {
      layout = "us, ru";
      variant = ",phonetic";
    };
  };

  services.printing.enable = true;

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-gnome
    ];
  };

  users.users.evgen2571 = {
    isNormalUser = true;
    description = "Eugene A";
    extraGroups = [
      "networkmanager"
      "wheel"
      "input"
      "git"
      "docker"
      "libvirtd"
    ];
    shell = pkgs.fish;
  };

  nixpkgs.config.allowUnfree = true;
  programs.nix-ld.enable = true;

  environment.systemPackages = with pkgs; [
    libreoffice-still
    microfetch
    xwayland
    xwayland-satellite
    wget
    nixd
    nil
    nix
    starship
    nodejs_24
    tree
    vulkan-tools
  ];

  fonts.enableDefaultPackages = true;
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    liberation_ttf
    dejavu_fonts
  ];

  nix.settings = {
    max-jobs = 1;
    cores = 2;
    eval-cache = true;
    substituters = [ "https://cache.nixos.org" ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
    fallback = false;
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  system.stateVersion = "25.11";
}
