{ lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./profile.nix
    ./secrets.nix
    ../../modules/system-core/common.nix
    ../../modules/system-core/user.nix
  ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

  # This machine has a single EFI System Partition mounted at /boot.
  boot.loader.efi.efiSysMountPoint = "/boot";

  networking.hostName = "nixos-lp";

  services.libinput.enable = true;

  services.fprintd.enable = true;
  # Enabling fprintd also enables PAM fingerprint auth by default for greetd.
  # Make login password-only: one prompt, with the password passed to GNOME Keyring.
  security.pam.services.greetd.fprintAuth = false;
  security.pam.services.sudo.fprintAuth = false;

  my.primaryUser = {
    enable = true;
    name = lib.mkDefault "operator";
    shell = pkgs.fish;
    extraGroups = [
      "networkmanager"
      "wheel"
      "libvirtd"
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

  system.stateVersion = "25.11";
}
