# configuration.nix
{ config, inputs, lib, ... }:
let
  cfg = config.my.system.apps.aagl;
in
{
  imports = [
    inputs.aagl.nixosModules.default
  ];

  options.my.system.apps.aagl.enable = lib.mkEnableOption "Anime Game Launcher";

  config = lib.mkIf cfg.enable {
    nix.settings = inputs.aagl.nixConfig; # Set up Cachix
    programs.anime-game-launcher.enable = true;
  };
}
