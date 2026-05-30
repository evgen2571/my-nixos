{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.system.apps.vesktop;

  unstable = import inputs.nixpkgs-unstable {
    system = pkgs.system;
    config.allowUnfree = true;
  };

  # Your nixpkgs Vesktop package does not expose an `electron` argument,
  # so do not use:
  #
  #   unstable.vesktop.override { electron = ...; }
  vesktopPackage = unstable.vesktop;

  vesktopWayland = pkgs.writeShellScriptBin "vesktop" ''
    export NIXOS_OZONE_WL=1
    export ELECTRON_OZONE_PLATFORM_HINT=wayland

    exec ${lib.getExe vesktopPackage} \
      --ozone-platform=wayland \
      --enable-features=UseOzonePlatform,WebRTCPipeWireCapturer,WaylandWindowDecorations \
      "$@"
  '';

  vesktopDebug = pkgs.writeShellScriptBin "vesktop-debug" ''
    export ELECTRON_ENABLE_LOGGING=1
    export NIXOS_OZONE_WL=1
    export ELECTRON_OZONE_PLATFORM_HINT=wayland

    exec ${lib.getExe vesktopPackage} \
      --ozone-platform=wayland \
      --enable-features=UseOzonePlatform,WebRTCPipeWireCapturer,WaylandWindowDecorations \
      --enable-logging=stderr \
      --v=1 \
      "$@"
  '';

  vesktopGpuWorkaround = pkgs.writeShellScriptBin "vesktop-gpu-workaround" ''
    export ELECTRON_ENABLE_LOGGING=1
    export NIXOS_OZONE_WL=1
    export ELECTRON_OZONE_PLATFORM_HINT=wayland

    exec ${lib.getExe vesktopPackage} \
      --ozone-platform=wayland \
      --enable-features=UseOzonePlatform,WebRTCPipeWireCapturer,WaylandWindowDecorations \
      --disable-gpu-memory-buffer-video-frames \
      --enable-logging=stderr \
      --v=1 \
      "$@"
  '';
in
{
  options.my.system.apps.vesktop.enable = lib.mkEnableOption "Vesktop";

  config = lib.mkIf cfg.enable {
    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      ELECTRON_OZONE_PLATFORM_HINT = "wayland";
    };

    environment.systemPackages = [
      (lib.hiPrio vesktopWayland)
      vesktopDebug
      vesktopGpuWorkaround
    ];
  };
}
