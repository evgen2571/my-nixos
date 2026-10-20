# Niri's built-in XWayland integration requires satellite on the session PATH.
{ configurations, pkgs }:

let
  lib = pkgs.lib;

  desktops = map (name: configurations.${name}.config) [
    "nixos-pc"
    "nixos-lp"
  ];
in
assert lib.all (
  c:
  c.programs.niri.enable
  && c.programs.xwayland.enable
  && lib.any (p: (p.pname or "") == "xwayland-satellite") c.environment.systemPackages
  && c.programs.steam.enable
  && c.programs.steam.gamescopeSession.enable
) desktops;
assert configurations.nixos-lp.config.services.desktopManager.gnome.enable;
pkgs.runCommand "niri-host-profile-checks" { } "touch $out"
