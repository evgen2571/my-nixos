{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.user.dev.ffmpeg;
in
{
  options.my.user.dev.ffmpeg.enable = lib.mkEnableOption "ffmpeg";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      ffmpeg
    ];
  };
}
