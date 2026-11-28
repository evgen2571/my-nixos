{
  config,
  lib,
  packageSources,
  ...
}:

let
  cfg = config.my.user.apps.pdfcraft;
in
{
  options.my.user.apps.pdfcraft.enable = lib.mkEnableOption "PdfCraft PDF reader and editor";

  config = lib.mkIf cfg.enable {
    home.packages = [ packageSources.pdfcraft ];

    xdg.mimeApps = rec {
      enable = true;
      defaultApplications."application/pdf" = [ "ai.storyteller.pdfcraft.desktop" ];
      associations.added = defaultApplications;
    };
  };
}
