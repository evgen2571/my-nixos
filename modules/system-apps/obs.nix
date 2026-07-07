{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.my.system.apps.obs;
  nvidiaEnabled = config.my.hardware.nvidia.enable or false;
in
{
  options.my.system.apps.obs.enable = lib.mkEnableOption "OBS Studio";

  config = lib.mkIf cfg.enable {
    programs.obs-studio = {
      enable = true;

      package = pkgs.obs-studio.override {
        cudaSupport = nvidiaEnabled;
      };

      plugins = with pkgs.obs-studio-plugins; [
        input-overlay
        obs-backgroundremoval
        obs-composite-blur
        obs-gstreamer
        obs-move-transition
        obs-pipewire-audio-capture
        obs-source-clone
        obs-vaapi
        obs-vkcapture
        wlrobs
      ];
    };

    environment.systemPackages = with pkgs; [
      ffmpeg
      v4l-utils
    ];
  };
}
