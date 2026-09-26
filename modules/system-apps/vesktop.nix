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
    system = pkgs.stdenv.hostPlatform.system;
    config = {
      allowUnfree = true;
      permittedInsecurePackages = [
        "electron-39.8.10"
        "pnpm-10.29.2"
      ];
    };
  };

  vesktop = pkgs.symlinkJoin {
    name = "vesktop-wayland";
    paths = [ unstable.vesktop ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/vesktop \
        --set NIXOS_OZONE_WL 1 \
        --set ELECTRON_OZONE_PLATFORM_HINT wayland \
        --add-flags "--ozone-platform=wayland" \
        --add-flags "--enable-features=UseOzonePlatform,WebRTCPipeWireCapturer,WaylandWindowDecorations"
    '';
    meta.mainProgram = "vesktop";
  };
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
