# configuration.nix
{ config, pkgs, ... }:
let
  # aagl = import (builtins.fetchTarball "https://github.com/ezKEa/aagl-gtk-on-nix/archive/main.tar.gz");
  # Or, if you follow Nixpkgs release 25.11:
  aagl = import (
    builtins.fetchTarball {
      url = "https://github.com/ezKEa/aagl-gtk-on-nix/archive/release-25.11.tar.gz";
      sha256 = "1pldvb23r9pf0x0h9a3sq0cfpdmpn2pqbww8sklw8n7fndl8vpr9";
    }
  );
in
{
  imports = [
    aagl.module
  ];

  nix.settings = aagl.nixConfig; # Set up Cachix
  # programs.anime-game-launcher.enable = true;
  # programs.anime-games-launcher.enable = true;
  # programs.honkers-railway-launcher.enable = true;
  # programs.honkers-launcher.enable = true;
  # programs.wavey-launcher.enable = true;
  # programs.sleepy-launcher.enable = true;
}
