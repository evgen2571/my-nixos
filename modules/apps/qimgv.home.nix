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

    xdg.mimeApps = rec {
      enable = true;

      defaultApplications = lib.genAttrs [
        "image/avif"
        "image/bmp"
        "image/gif"
        "image/heic"
        "image/heif"
        "image/jpeg"
        "image/jxl"
        "image/png"
        "image/svg+xml"
        "image/tiff"
        "image/vnd.microsoft.icon"
        "image/webp"
        "image/x-icon"
        "image/x-portable-bitmap"
        "image/x-portable-graymap"
        "image/x-portable-pixmap"
        "image/x-xbitmap"
        "image/x-xpixmap"
      ] (_: [ "qimgv.desktop" ]);

      associations.added = defaultApplications;
    };
  };
}
