{ configurations, pkgs }:

let
  host = configurations.nixos-pc.config;
  home = host.home-manager.users.${host.my.primaryUser.name};
  menu = pkgs.writeText "applications.menu" home.xdg.configFile."menus/applications.menu".text;
in
pkgs.runCommand "dolphin-open-files-checks"
  {
    nativeBuildInputs = [
      pkgs.dbus
      pkgs.python3
      pkgs.kdePackages.kde-cli-tools.out
      pkgs.kdePackages.kservice.out
    ];
  }
  ''
    dbus-run-session --config-file=${pkgs.dbus}/share/dbus-1/session.conf -- python3 ${./open-files.py} \
      --menu ${menu} \
      --mimeapps ${home.xdg.configFile."mimeapps.list".source} \
      --mime-data ${pkgs.shared-mime-info}/share
    touch $out
  ''
