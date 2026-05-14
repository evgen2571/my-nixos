{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.user.apps.youtubeMusic;
in
{
  options.my.user.apps.youtubeMusic.enable = lib.mkEnableOption "YouTube Music";

  config = lib.mkIf cfg.enable ({
    home.packages = with pkgs; [
      youtube-music
      yt-dlp
    ];
  });
}
