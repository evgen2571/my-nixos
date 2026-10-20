{ lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./profile.nix
    ./secrets.nix
    ../../modules/system-core/common.nix
    ../../modules/system-core/user.nix
  ];

  # This machine uses a separate EFI System Partition and XBOOTLDR partition.
  boot.loader = {
    efi.efiSysMountPoint = "/efi";
    systemd-boot.xbootldrMountPoint = "/boot";
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

  swapDevices = [
    {
      device = "/swapfile";
      size = 16384;
    }
  ];

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
