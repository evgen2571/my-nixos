{ lib,  config, pkgs, ... }:

let
  cfg = config.my.hardware.nvidia;
in
{
  options.my.hardware.nvidia.enable = lib.mkEnableOption "NVIDIA graphics support";

  config = lib.mkIf cfg.enable (
    {
      services.xserver.videoDrivers = [ "nvidia" ];

      hardware.graphics = {
        enable = true;
        enable32Bit = true;
      };

      hardware.nvidia = {
        modesetting.enable = true;
        powerManagement.enable = false;
        open = false;
        package = config.boot.kernelPackages.nvidiaPackages.stable;
      };

      boot.kernelParams = [ "nvidia-drm.modeset=1" ];

      programs.xwayland.enable = true;
    }
  );
}
