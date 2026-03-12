{
  lib,
  pkgs,
  wm,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/hardware/nvidia.nix

    ../../modules/wm/niri
    ../../modules/wm/opentabletdriver.nix
    ../../modules/wm/gnome
    ../../modules/wm/ly.nix

    ../../modules/coding/fish

    ../../modules/ai/ollama.nix

    ../../modules/apps/steam.nix
    ../../modules/apps/aagl.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos-pc";
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

  # Enable a basic set of fonts for good Unicode coverage
  fonts.enableDefaultPackages = true;

  # Add common font packages
  fonts.packages = with pkgs; [
    noto-fonts # Basic emoji and general purpose fonts
    noto-fonts-cjk-sans # Chinese, Japanese, Korean support
    noto-fonts-color-emoji
    liberation_ttf # Free replacements for Arial, Times, Courier
    dejavu_fonts # Wide Unicode coverage
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
