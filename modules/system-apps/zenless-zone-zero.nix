{ config, lib, ... }:

let
  cfg = config.my.system.apps.zenlessZoneZero;
in
{
  options.my.system.apps.zenlessZoneZero.enable = lib.mkEnableOption "Zenless Zone Zero launcher";

  config = lib.mkIf cfg.enable {
    # Provided by the AAGL module imported in aagl.nix. This launcher supports
    # Zenless Zone Zero alongside the other anime games.
    programs.sleepy-launcher.enable = true;
  };
}
