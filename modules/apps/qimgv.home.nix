{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.user.apps.qimgv;
in
{
  options.my.user.apps.qimgv.enable = lib.mkEnableOption "qimgv image viewer";

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.qimgv
    ];

    xdg.mimeApps = {
      enable = true;

      defaultApplications = {
        "image/*" = [ "qimgv.desktop" ];
      };
    };
  };
}
