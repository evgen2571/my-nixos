# configuration.nix
{ config, pkgs, lib, ... }:
let
  cfg = config.my.system.apps.aagl;

  # aagl = import (builtins.fetchTarball "https://github.com/ezKEa/aagl-gtk-on-nix/archive/main.tar.gz");
  # Or, if you follow Nixpkgs release 25.11:
  aagl = import (
    builtins.fetchTarball {
      url = "https://github.com/ezKEa/aagl-gtk-on-nix/archive/release-25.11.tar.gz";
      sha256 = "09j214f9ad8vqw11bfjm8g0bvalyymnk9imwr2nz42d8fpiv8zf2";
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
