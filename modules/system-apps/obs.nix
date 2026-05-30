{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.my.system.apps.obs;
in
{
  options.my.system.apps.obs.enable = lib.mkEnableOption "OBS Studio";

  config = lib.mkIf cfg.enable ({
    programs.obs-studio = {
      enable = true;

      # optional Nvidia hardware acceleration
      package = (
        pkgs.obs-studio.override {
          cudaSupport = true;
        }
      );

      plugins = with pkgs.obs-studio-plugins; [
        wlrobs
        obs-backgroundremoval
        obs-pipewire-audio-capture
        obs-vaapi # optional AMD hardware acceleration
        obs-gstreamer
        obs-vkcapture
      ];
    };
  });
}
