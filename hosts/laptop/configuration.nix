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
  security.pam.services.ly.fprintAuth = true;
  security.pam.services.sudo.fprintAuth = false;

  my.primaryUser = {
    enable = true;
    name = "operator";
    description = "Operator";
    shell = pkgs.fish;
    extraGroups = [
      "networkmanager"
      "wheel"
      "libvirtd"
      "input"
      "git"
    ];

    git = {
      userEmail = "150374952+evgen2571@users.noreply.github.com";
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
