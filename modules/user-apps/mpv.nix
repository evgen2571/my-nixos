{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.user.apps.mpv;
in
{
  options.my.user.apps.mpv.enable = lib.mkEnableOption "MPV";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      mpv
    ];

    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "video/*" = [ "mpv.desktop" ];
      };
    };
  };
}
