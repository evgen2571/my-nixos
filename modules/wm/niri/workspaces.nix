{ config, lib, ... }:

let
  host = config.networking.hostName;

  workspaces = [ "browser" "chats" "notes" "code" "gaming" ];

  outputForHost =
    if host == "nixos-pc" then {
      "browser" = "DP-1";
      "chats"   = "DP-1";
      "notes"   = "HDMI-A-1";
      "code"    = "HDMI-A-1";
      "gaming"  = "HDMI-A-1";
    } else if host == "nixos-lp" then {
	  "code"    = "eDP-1";
      "browser" = "eDP-1";
	  "notes" = "eDP-1";
      "chats"   = "eDP-1";
      "gaming"  = "eDP-1";
    } else {};
in
{
  programs.niri.settings.workspaces =
    lib.genAttrs workspaces (name: {
      open-on-output = outputForHost.${name} or null;
    });
}
