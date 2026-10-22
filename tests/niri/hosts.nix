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
  let
    mimeApps = c.home-manager.users.${c.my.primaryUser.name}.xdg.mimeApps;
    defaults = mimeApps.defaultApplications;
  in
  lib.all (mime: defaults.${mime} or [ ] == [ "mpv.desktop" ]) [
    "audio/mpeg"
    "audio/flac"
    "audio/x-wav"
    "video/mp4"
    "video/x-matroska"
    "video/webm"
  ]
  && lib.all (mime: defaults.${mime} or [ ] == [ "qimgv.desktop" ]) [
    "image/png"
    "image/jpeg"
    "image/gif"
    "image/webp"
  ]
  && !(defaults ? "audio/*" || defaults ? "video/*" || defaults ? "image/*")
  && lib.all (
    mime: lib.all (app: builtins.elem app (mimeApps.associations.added.${mime} or [ ])) defaults.${mime}
  ) (builtins.attrNames defaults)
) desktops;
assert lib.all (
  c:
  c.programs.niri.enable
  && c.programs.xwayland.enable
  && lib.any (p: (p.pname or "") == "xwayland-satellite") c.environment.systemPackages
  && c.programs.steam.enable
  && c.programs.steam.gamescopeSession.enable
  && c.security.polkit.enable
  && c.services.udisks2.enable
  && lib.any (
    p: (p.pname or "") == "wayscriber"
  ) c.home-manager.users.${c.my.primaryUser.name}.home.packages
  && lib.any (p: (p.pname or "") == "xdg-desktop-portal-kde") c.xdg.portal.extraPortals
  && c.xdg.portal.config.niri."org.freedesktop.impl.portal.FileChooser" == "gtk"
  && c.home-manager.users.${c.my.primaryUser.name}.xdg.configFile ? "menus/applications.menu"
  && builtins.elem "graphical-session.target" c.systemd.user.services.polkit-gnome-authentication-agent-1.wantedBy
  && c.systemd.user.services.polkit-gnome-authentication-agent-1.serviceConfig.Restart == "on-failure"
  && !c.home-manager.users.${c.my.primaryUser.name}.programs.noctalia.settings.shell.polkit_agent
) desktops;
assert configurations.nixos-lp.config.services.desktopManager.gnome.enable;
pkgs.runCommand "niri-host-profile-checks" { } "touch $out"
