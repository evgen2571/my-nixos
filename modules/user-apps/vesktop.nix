{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.user.apps.vesktop;
in
{
  options.my.user.apps.vesktop.enable = lib.mkEnableOption "Vesktop";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      vesktop
    ];

    home.sessionVariables.NIXOS_OZONE_WL = "1";

    xdg.desktopEntries.vesktop = {
      name = "Vesktop";
      genericName = "Discord client";
      exec = "env NIXOS_OZONE_WL=1 ${lib.getExe pkgs.vesktop} --enable-features=WebRTCPipeWireCapturer";
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
