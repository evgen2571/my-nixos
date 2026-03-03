{ config, pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    starship
  ];

  xdg.configFile."starship.toml".source = ./starship.toml;
}
