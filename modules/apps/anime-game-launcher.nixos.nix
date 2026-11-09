{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.system.apps.animeGameLauncher;
in
{
  imports = [ inputs.aagl.nixosModules.default ];

  options.my.system.apps.animeGameLauncher.enable = lib.mkEnableOption "Anime Game Launcher";

  config = lib.mkIf cfg.enable {
    programs.anime-game-launcher = {
      enable = true;

      package = pkgs.anime-game-launcher.override {
        extraPkgs = pkgs: [
          pkgs.dejavu_fonts
        ];
      };
    };
  };
}
