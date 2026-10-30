{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.user.desktop.cursors;
in
{
  options.my.user.desktop.cursors.enable = lib.mkEnableOption "Phinger cursor theme";

  config = lib.mkIf cfg.enable {
    home.pointerCursor = {
      enable = true;
      package = pkgs.phinger-cursors;
      name = "phinger-cursors-dark";
      size = 24;
      gtk.enable = true;
      x11.enable = true;
    };
  };
}
