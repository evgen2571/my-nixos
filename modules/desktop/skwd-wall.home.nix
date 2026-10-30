{
  config,
  lib,
  pkgs,
  packageSources,
  ...
}:

let
  cfg = config.my.user.desktop.skwdWall;
  package = packageSources.skwd-wall;
  defaults = (pkgs.formats.json { }).generate "skwd-wall-config.json" (
    builtins.fromJSON (builtins.readFile ../../config/skwd-wall/config.json)
    // {
      paths = {
        wallpaper = config.wallpapers.directory;
        videoWallpaper = config.wallpapers.directory;
      }
      // lib.optionalAttrs config.my.user.desktop.noctalia.enable {
        noctaliaBin = "${config.home.profileDirectory}/bin/noctalia";
      };
    }
  );
in
{
  options.my.user.desktop.skwdWall.enable = lib.mkEnableOption "Skwd wallpaper picker and renderer";

  config = lib.mkIf cfg.enable {
    home.packages = [ package ];
    fonts.fontconfig.enable = lib.mkDefault true;

    # Skwd saves GUI settings here; seed a writable file without replacing it.
    home.activation.seedSkwdWallConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ ! -e "${config.xdg.configHome}/skwd-wall-v2/config.json" ] && [ ! -L "${config.xdg.configHome}/skwd-wall-v2/config.json" ]; then
        run ${pkgs.coreutils}/bin/install -Dm600 ${defaults} "${config.xdg.configHome}/skwd-wall-v2/config.json"
      fi
    '';

    systemd.user.services.skwd-walld = {
      Unit = {
        Description = "Skwd wallpaper daemon";
        Conflicts = [ "skwd-daemon.service" ];
        PartOf = [ "graphical-session.target" ];
        After = [
          "graphical-session.target"
        ]
        ++ lib.optional config.programs.noctalia.systemd.enable "noctalia.service";
      };
      Service = {
        ExecStart = "${package}/bin/skwd-walld";
        Restart = "on-failure";
        RestartSec = 2;
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    programs.noctalia.settings = lib.mkIf config.my.user.desktop.noctalia.enable {
      wallpaper.enabled = false;
      widget.wallpaper.actions.left = "exec ${package}/bin/skwd-wall-v2";
    };
  };
}
