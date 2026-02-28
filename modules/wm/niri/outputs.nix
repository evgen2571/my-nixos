{ config, lib, ... }:

let
  host = config.networking.hostName;
in
{
  programs.niri.settings.outputs =
    lib.mkMerge [
      # laptop
      (lib.mkIf (host == "nixos-lp") {
        "eDP-1" = {
          mode = "1920x1080@120.030";
          scale = 1;
          transform = "normal";
          position = { x = 0; y = 0; };
        };
      })

      # PC
      (lib.mkIf (host == "nixos-pc") {
        "DP-1" = {
          mode = "2560x1440@59.951";
          scale = 1;
          transform = "normal";
          position = { x = 0; y = 0; };
        };

        "HDMI-A-1" = {
          mode = "2560x1440@99.946";
          scale = 1;
          transform = "normal";
          position = { x = 2560; y = 0; };
        };
      })
    ];
}
