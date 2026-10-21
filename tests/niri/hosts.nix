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
  && c.security.polkit.enable
  && builtins.elem "graphical-session.target" c.systemd.user.services.polkit-gnome-authentication-agent-1.wantedBy
  && c.systemd.user.services.polkit-gnome-authentication-agent-1.serviceConfig.Restart == "on-failure"
  && !c.home-manager.users.${c.my.primaryUser.name}.programs.noctalia.settings.shell.polkit_agent
) desktops;
assert configurations.nixos-lp.config.services.desktopManager.gnome.enable;
pkgs.runCommand "niri-host-profile-checks" { } "touch $out"
