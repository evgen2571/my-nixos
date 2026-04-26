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

  my.system.user = {
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
  };

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  system.stateVersion = "25.11";
}
