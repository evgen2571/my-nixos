{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.user.apps.anki;
in
{
  options.my.user.apps.anki.enable = lib.mkEnableOption "Anki Flashcards";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      anki-bin
    ];
  };
}
