{ lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    ./game-storage.nix
    ./recovery.nix
    ./profile.nix
    ./secrets.nix
    ../../modules/core/desktop-baseline.nixos.nix
    ../../modules/core/primary-user.nixos.nix
  ];

  boot.loader.efi.efiSysMountPoint = "/boot";

  services.fstrim.enable = true;
  services.fstrim.interval = "weekly";
  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = [ "/" ];
  };

  networking.hostName = "nixos-pc";

  programs.nm-applet.enable = true;
  services.printing.enable = true;
  security.rtkit.enable = true;

  hardware.uinput.enable = true;

  my.primaryUser = {
    enable = true;
    name = lib.mkDefault "operator";
    shell = pkgs.fish;

    extraGroups = [
      "networkmanager"
      "wheel"
      "input"
      "git"
      "docker"
      "libvirtd"
      "uinput"
    ];
  };

  environment.systemPackages = with pkgs; [
    xwayland-satellite
    vulkan-tools
  ];

  nix.settings = {
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];

    fallback = false;
  };

  system.stateVersion = "25.11";
}
