{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.my.system.apps.lutris;
in
{
  options.my.system.apps.lutris.enable = lib.mkEnableOption "Lutris";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      (lutris.override {
        extraPkgs = _: [
          wineWowPackages.stagingFull
          winetricks
        ];
      })
    ];
  };
}
