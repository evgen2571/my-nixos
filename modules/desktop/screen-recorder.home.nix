{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.user.desktop.screenRecorder;
in
{
  options.my.user.desktop.screenRecorder.enable = lib.mkEnableOption "screen recording tools";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      # Low-overhead GPU recording, plus a tray/GUI frontend.
      gpu-screen-recorder
      gpu-screen-recorder-gtk

      # Wayland fallback tools and quick capture helpers.
      wf-recorder
      grim
      slurp

      # Screen annotation for presentations and recordings.
      wayscriber

      # PipeWire audio routing/inspection helpers for recording setups.
      pavucontrol
      qpwgraph
    ];
  };
}
