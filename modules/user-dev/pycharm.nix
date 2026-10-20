{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.user.dev.pycharm;
in
{
  options.my.user.dev.pycharm.enable = lib.mkEnableOption "PyCharm";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      jetbrains.pycharm
    ];
  };
}
