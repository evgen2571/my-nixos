{ config, lib,  pkgs, ... }:

let
  cfg = config.my.user.desktop.screenRecorder;
in
{
  options.my.user.desktop.screenRecorder.enable = lib.mkEnableOption "GPU screen recorder";

  config = lib.mkIf cfg.enable (
    {
      home.packages = with pkgs; [
        gpu-screen-recorder
      ];
    }
  );
}
