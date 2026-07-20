{
  config,
  lib,
  ...
}:

let
  cfg = config.my.desktop.kdeplasma;
in
{
  options.my.desktop.kdeplasma.enable = lib.mkEnableOption "KDE Plasma desktop environment";

  config = lib.mkIf cfg.enable {
    services.desktopManager.plasma6.enable = true;
  };
}
