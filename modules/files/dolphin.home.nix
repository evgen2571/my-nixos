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

  config = lib.mkIf cfg.enable {
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
