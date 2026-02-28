{ config, lib, ... }:

let
  host = config.networking.hostName;
in
{
  programs.niri.settings.spawn-at-startup =
    [ "noctalia-shell" "xwayland-satellite" ]
    ++ lib.optionals (host == "nixos-pc") [
      "zen-twilight"
      "obsidian"
    ]
    ++ lib.optionals (host == "nixos-lp") [
      "obsidian"
    ];
}
