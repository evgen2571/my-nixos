{
  config,
  lib,
  packageSources,
  ...
}:

let
  cfg = config.my.user.apps.sonora;
in
{
  options.my.user.apps.sonora.enable = lib.mkEnableOption "Sonora";

  config = lib.mkIf cfg.enable {
    home.packages = [ packageSources.sonora ];
  };
}
