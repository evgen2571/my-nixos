{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.user.apps.vesktop;
  unstable = import inputs.nixpkgs-unstable {
    system = pkgs.system;
    config.allowUnfree = true;
  };
  vesktopPackage = unstable.vesktop;
  vesktopWayland = pkgs.writeShellScriptBin "vesktop" ''
    export NIXOS_OZONE_WL=1
    export ELECTRON_OZONE_PLATFORM_HINT=wayland
    exec ${lib.getExe vesktopPackage} \
      --ozone-platform=wayland \
      --enable-features=UseOzonePlatform,WebRTCPipeWireCapturer \
      "$@"
  '';
in
{
  options.my.user.apps.vesktop.enable = lib.mkEnableOption "Vesktop";

  config = lib.mkIf cfg.enable {
    home.packages = [
      vesktopWayland
    ];

    home.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      ELECTRON_OZONE_PLATFORM_HINT = "wayland";
    };

    xdg.desktopEntries.vesktop = {
      name = "Vesktop";
      genericName = "Discord client";
      exec = "${lib.getExe vesktopWayland} %U";
      terminal = false;
      type = "Application";
      icon = "vesktop";
      categories = [
        "Network"
        "InstantMessaging"
        "Chat"
      ];
    };
  };
}
