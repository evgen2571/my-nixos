{ pkgs, ... }:

{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.networkmanager.enable = true;
  networking.networkmanager.plugins = with pkgs; [
    networkmanager-openvpn
  ];

  time.timeZone = "Europe/Minsk";
  i18n.defaultLocale = "en_US.UTF-8";

  services.xserver = {
    enable = true;
    xkb = {
      layout = "us, ru";
      variant = ",phonetic";
    };
  };

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    wireplumber.enable = true;
  };

  nixpkgs.config.allowUnfree = true;
  programs.nix-ld.enable = true;

  environment.systemPackages = with pkgs; [
    libreoffice-still
    microfetch
    xwayland
    wget
    nixd
    nil
    nix
    starship
    nodejs_24
    tree
  ];

  nix.settings = {
    max-jobs = 1;
    cores = 2;
    eval-cache = true;
    substituters = [ "https://cache.nixos.org" ];
    experimental-features = [
      "nix-command"
      "flakes"
    ];
  };
}
