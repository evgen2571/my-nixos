{ pkgs, ... }:

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
  # Fingerprint support remains available; greetd uses password authentication
  # by default to avoid blocking password entry and GNOME Keyring unlocking.
  security.pam.services.sudo.fprintAuth = false;

  my.primaryUser = {
    enable = true;
    name = "evgen2571";
    description = "Eugene A";
    shell = pkgs.fish;
    extraGroups = [
      "networkmanager"
      "wheel"
      "libvirtd"
      "input"
      "git"
    ];

    git = {
      userEmail = "evgen.10.02.2008.83@gmail.com";
      signingKey = "~/.ssh/id_ed25519_github";
    };
  };

  swapDevices = [
    {
      device = "/swapfile";
      size = 16384;
    }
  ];

  system.stateVersion = "25.11";
}
