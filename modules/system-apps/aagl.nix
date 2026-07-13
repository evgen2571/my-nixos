# configuration.nix
{ config, inputs, lib, pkgs, ... }:
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
    programs.anime-game-launcher = {
      enable = true;

      # AAGL runs inside its own Steam/FHS environment.  Add the host's
      # Unicode fonts there as well; otherwise CJK and less common glyphs
      # can be rendered as empty squares by the launcher/game.
      package = pkgs.anime-game-launcher.override {
        extraPkgs = _pkgs: with _pkgs; [
          fontconfig
          noto-fonts-cjk-sans
          noto-fonts-cjk-serif
          noto-fonts-color-emoji
          unifont
        ];
      };
    };
  };
}
