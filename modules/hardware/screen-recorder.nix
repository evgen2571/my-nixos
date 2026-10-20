{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.hardware.screenRecorder;
in
{
  options.my.hardware.screenRecorder.enable = lib.mkEnableOption "screen recording hardware support";

  config = lib.mkIf cfg.enable {
    # Provides the privileged gsr-kms-server wrapper required by GPU Screen Recorder
    # for promptless capture on KMS/Wayland sessions.
    programs.gpu-screen-recorder.enable = true;

    environment.systemPackages = with pkgs; [
      libva-utils
      vulkan-tools
    ];
  };
}
