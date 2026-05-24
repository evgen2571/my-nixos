# configuration.nix
{ config, pkgs, lib, ... }:
let
  cfg = config.my.system.apps.aagl;

  # aagl = import (builtins.fetchTarball "https://github.com/ezKEa/aagl-gtk-on-nix/archive/main.tar.gz");
  # Or, if you follow Nixpkgs release 25.11:
  aagl = import (
    builtins.fetchTarball {
      url = "https://github.com/ezKEa/aagl-gtk-on-nix/archive/release-25.11.tar.gz";
      sha256 = "0790jqa5anb3ggflw5is9d4rpr2ra6w10yglhwqps1j49ac7d67m";
    }
  );
in
{
  imports = [
    aagl.module
  ];

  options.my.system.apps.aagl.enable = lib.mkEnableOption "Anime Game Launcher";

  config = lib.mkIf cfg.enable {
    nix.settings = aagl.nixConfig; # Set up Cachix
    programs.anime-game-launcher.enable = true;
  };
}
