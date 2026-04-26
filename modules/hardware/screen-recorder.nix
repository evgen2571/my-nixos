{ config, lib, ... }:

let
  cfg = config.my.hardware.screenRecorder;
in
{
  options.my.hardware.screenRecorder.enable = lib.mkEnableOption "GPU screen recorder hardware support";

  config = lib.mkIf cfg.enable { };
}
