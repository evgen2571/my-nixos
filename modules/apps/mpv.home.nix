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

    xdg.mimeApps = rec {
      enable = true;

      defaultApplications = lib.genAttrs [
        "application/ogg"
        "application/x-matroska"
        "application/x-mpegurl"
        "application/vnd.apple.mpegurl"
        "audio/aac"
        "audio/flac"
        "audio/mp4"
        "audio/mpeg"
        "audio/ogg"
        "audio/opus"
        "audio/vnd.wave"
        "audio/wav"
        "audio/webm"
        "audio/x-aiff"
        "audio/x-flac"
        "audio/x-m4a"
        "audio/x-matroska"
        "audio/x-mpegurl"
        "audio/x-ms-wma"
        "audio/x-scpls"
        "audio/x-vorbis+ogg"
        "audio/x-wav"
        "video/3gpp"
        "video/3gpp2"
        "video/mp2t"
        "video/mp4"
        "video/mpeg"
        "video/ogg"
        "video/quicktime"
        "video/webm"
        "video/x-flv"
        "video/x-m4v"
        "video/x-matroska"
        "video/x-ms-asf"
        "video/x-ms-wmv"
        "video/x-msvideo"
      ] (_: [ "mpv.desktop" ]);

      associations.added = defaultApplications;
    };
  };
}
