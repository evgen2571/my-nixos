{
  config,
  lib,
  pkgs,
  ...
}:
let
  home = config.home.homeDirectory;
in
{
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    setSessionVariables = true;
    download = "${home}/downloads";
    pictures = "${home}/pictures";
    projects = "${home}/dev";
    # XDG disables an unused directory by pointing it at the home itself.
    desktop = home;
    documents = home;
    music = home;
    publicShare = home;
    templates = home;
    videos = home;
  };

  home.file = {
    games.source = config.lib.file.mkOutOfStoreSymlink "/games";
    "${config.xdg.dataHome}/Steam/steamapps".source =
      config.lib.file.mkOutOfStoreSymlink "/games/steam/steamapps";
    "${config.xdg.dataHome}/PrismLauncher/instances".source =
      config.lib.file.mkOutOfStoreSymlink "/games/minecraft/instances";
  };

  home.activation.checkPcHomeLayout = lib.hm.dag.entryBefore [ "checkLinkTargets" "writeBoundary" ] ''
    PATH=${
      lib.makeBinPath [
        pkgs.coreutils
        pkgs.util-linux
        pkgs.btrfs-progs
        pkgs.gawk
        pkgs.findutils
      ]
    }:$PATH \
      ${pkgs.bash}/bin/bash ${./check-home-layout.sh} \
      ${lib.escapeShellArgs [
        home
        config.xdg.dataHome
        config.xdg.userDirs.pictures
        "/games"
      ]}
  '';
}
