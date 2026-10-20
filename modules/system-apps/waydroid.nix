{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.my.system.apps.waydroid;
in
{
  options.my.system.apps.waydroid.enable = lib.mkEnableOption "Waydroid";

  config = lib.mkIf cfg.enable {
    virtualisation.waydroid.enable = true;
    virtualisation.waydroid.package = pkgs.waydroid-nftables;
  };
}
