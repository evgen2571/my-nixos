{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.user.files.dolphin;

  dolphin = pkgs.symlinkJoin {
    name = "dolphin-${pkgs.kdePackages.dolphin.version}";
    paths = [ pkgs.kdePackages.dolphin ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/dolphin \
        --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ pkgs.pipewire ]}
    '';
    meta = pkgs.kdePackages.dolphin.meta;
  };
in
{
  options.my.user.files.dolphin.enable = lib.mkEnableOption "Dolphin file manager";

  options.my.user.files.dolphin.places = lib.mkOption {
    type = lib.types.nullOr (
      lib.types.listOf (
        lib.types.submodule {
          options = {
            url = lib.mkOption {
              type = lib.types.str;
              description = "Absolute bookmark URL, without embedded credentials.";
            };
            name = lib.mkOption {
              type = lib.types.nonEmptyStr;
              description = "Places sidebar label.";
            };
            icon = lib.mkOption {
              type = lib.types.str;
              default = "folder";
              description = "Freedesktop icon name.";
            };
          };
        }
      )
    );
    default = null;
    description = "Ordered personal Places; null leaves bookmarks unmanaged, [] removes previously managed pins.";
  };

  config = lib.mkIf cfg.enable {
    home.activation.syncDolphinPlaces = lib.mkIf (cfg.places != null) (
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run ${pkgs.python3}/bin/python3 ${./sync-dolphin-places.py} \
          ${pkgs.writeText "dolphin-places.json" (builtins.toJSON cfg.places)} \
          ${lib.escapeShellArg "${config.xdg.dataHome}/user-places.xbel"}
      ''
    );

    # KService only indexes desktop applications included by an XDG menu.
    xdg.configFile."menus/applications.menu".text = ''
      <!DOCTYPE Menu PUBLIC "-//freedesktop//DTD Menu 1.0//EN"
        "http://www.freedesktop.org/standards/menu-spec/1.0/menu.dtd">
      <Menu>
        <Name>Applications</Name>
        <DefaultAppDirs/>
        <DefaultDirectoryDirs/>
        <DefaultMergeDirs/>
        <Include><All/></Include>
      </Menu>
    '';

    home.packages = with pkgs; [
      kdePackages.qtsvg
      kdePackages.kio
      kdePackages.kio-fuse
      kdePackages.kio-extras
      kdePackages.plasma-integration
      kdePackages.breeze
      dolphin
      kdePackages.ark
    ];
  };
}
