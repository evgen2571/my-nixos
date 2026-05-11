{
  lib,
  configPaths,
  config,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.my.user.dev.fishConfig;
in
{
  options.my.user.dev.fishConfig.enable = lib.mkEnableOption "Fish user configuration";

  config = lib.mkIf cfg.enable ({
    xdg.configFile."fish".source = configPaths.coding.fishConfigDir;
  });
}
