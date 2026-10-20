{
  config,
  packageSources,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.system.apps.vesktop;

  vesktop = pkgs.symlinkJoin {
    name = "vesktop-wayland";
    paths = [ packageSources.vesktop ];
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
