{ pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
	../../modules/hardware/nvidia.nix
    ../../modules/wm/niri
    ../../modules/wm/ly.nix
    ../../modules/coding/fish.nix
    ../../modules/apps/steam.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos-pc";
  networking.networkmanager.enable = true;

  time.timeZone = "UTC";
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
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  users.users.operator = {
    isNormalUser = true;
    description = "Operator";
    extraGroups = [ "networkmanager" "wheel" "input" "git" ];
    shell = pkgs.fish;
  };

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    libreoffice-still
    microfetch
    xwayland-satellite
    xwayland
    wget
    starship
    nodejs_24
    codex
    tree
    youtube-tui
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  system.stateVersion = "25.11";
}
