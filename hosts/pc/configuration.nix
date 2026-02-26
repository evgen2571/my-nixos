{ pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/wm/niri.nix
    ../../modules/wm/ly.nix
    ../../modules/coding/fish.nix
    ../../modules/apps/steam.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos-pc";
  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Minsk";
  i18n.defaultLocale = "en_US.UTF-8";

  services.xserver = {
    enable = true;
    videoDrivers = [ "nvidia" ];
    xkb = {
      layout = "us, ru";
      variant = ",phonetic";
    };
  };

  hardware.graphics.enable = true;
  programs.gamescope.enable = true;
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    open = false;
  };

  services.printing.enable = true;

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  users.users.evgen2571 = {
    isNormalUser = true;
    description = "Eugene A";
    extraGroups = [ "networkmanager" "wheel" "input" ];
    shell = pkgs.fish;
  };

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    xwayland-satellite
    xwayland
    wget
    starship
    nodejs_24
    codex
    tree
    youtube-tui
  ];

  services.openssh.enable = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  system.stateVersion = "25.11";
}
