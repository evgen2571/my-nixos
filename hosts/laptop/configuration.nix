{
  lib,
  pkgs,
  wm,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix

    ../../modules/wm/niri
    ../../modules/wm/ly.nix

    ../../modules/coding/fish

    ../../modules/apps/steam.nix

    ../../modules/ai/ollama.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "nixos-lp";
  networking.networkmanager.enable = true;

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
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  services.libinput.enable = true;

  users.users.evgen2571 = {
    isNormalUser = true;
    description = "Eugene A";
    extraGroups = [
      "networkmanager"
      "wheel"
      "input"
      "git"
    ];
    shell = pkgs.fish;
  };

  nixpkgs.config.allowUnfree = true;
  programs.nix-ld.enable = true;

  environment.systemPackages = with pkgs; [
    libreoffice-still
    microfetch
    xwayland
    nixd
    nil
    nix
    wget
    starship
    nodejs_24
    tree
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  nix.settings = {
    max-jobs = 1;
    cores = 2;
    eval-cache = true;
    substituters = [ "https://cache.nixos.org" ];
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  system.stateVersion = "25.11";
}
