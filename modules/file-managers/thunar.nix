{ config, pkgs, ... }:

{
  programs.thunar.enable = true;
  services.gvfs.enable = true;
  services.tumbler.enable = true;

  environment.systemPackages = with pkgs; [
    adw-gtk3
    nwg-look
  ];
}
