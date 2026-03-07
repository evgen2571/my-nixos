{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    starship
  ];

  xdg.configFile."starship.toml".source = ./starship.toml;
}
