{
  config,
  lib,
  packageSources,
  ...
}:

let
  cfg = config.my.user.files.luciole;
in
{
  options.my.user.files.luciole.enable = lib.mkEnableOption "Luciole file manager";

  config = lib.mkIf cfg.enable {
    home.packages = [ packageSources.luciole ];

    xdg.mimeApps = {
      enable = true;
      defaultApplications."inode/directory" = [ "dev.noctalia.luciole.desktop" ];
    };

    # Prefer Luciole for Reveal in File Manager when other providers are installed.
    xdg.dataFile."dbus-1/services/org.freedesktop.FileManager1.service".source =
      "${packageSources.luciole}/share/dbus-1/services/dev.noctalia.luciole.FileManager1.service";
  };
}
