{
  config,
  lib,
  packageSources,
  ...
}:

let
  cfg = config.my.user.apps.helium;
in
{
  options.my.user.apps.helium.enable = lib.mkEnableOption "Helium browser";

  config = lib.mkIf cfg.enable {
    home.packages = [ packageSources.helium ];
  };
}
