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

  vesktop = pkgs.writeShellScriptBin "vesktop" ''
    export NIXOS_OZONE_WL=1
    export ELECTRON_OZONE_PLATFORM_HINT=wayland

    exec ${lib.getExe unstable.vesktop} \
      --ozone-platform=wayland \
      --enable-features=UseOzonePlatform,WebRTCPipeWireCapturer,WaylandWindowDecorations \
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
      vesktop
    ];
  };
}
