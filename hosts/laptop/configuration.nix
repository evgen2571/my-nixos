{ modulePaths, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./profile.nix
    modulePaths.system.common
    modulePaths.system.user
  ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "nixos-lp";

  services.libinput.enable = true;

  services.fprintd.enable = true;
  security.pam.services.ly.fprintAuth = true;
  security.pam.services.sudo.fprintAuth = false;

  my.primaryUser = {
    enable = true;
    name = "evgen2571";
    description = "Eugene A";
    shell = pkgs.fish;
    extraGroups = [
      "networkmanager"
      "wheel"
      "input"
      "git"
    ];

    git = {
      userEmail = "evgen.10.02.2008.83@gmail.com";
      signingKey = "~/.ssh/id_ed25519.pub";
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
