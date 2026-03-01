{ lib, pkgs, wm, ... }:

{
  imports = [
    ./hardware-configuration.nix
    (lib.getAttr wm {
      hyprland = ../../modules/wm/hyprland;
      niri = ../../modules/wm/niri;
    })
    ../../modules/wm/ly.nix
    ../../modules/coding/fish.nix
    ../../modules/apps/steam.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "nixos-lp";
  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Minsk";

  services.xserver.xkb = {
    layout = "us, ru";
    options = "caps:escape";
  };

  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  services.libinput.enable = true;

  users.users.evgen2571 = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    packages = with pkgs; [
      tree
    ];
  };

  environment.systemPackages = with pkgs; [
    wget
    git
    kitty
    unzip
    nixd
    nil
    nix
    nodejs_24
    rustc
    xwayland-satellite
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  system.stateVersion = "25.11";
}
