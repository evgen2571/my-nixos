{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.user.files.yazi;
in
{
  options.my.user.files.yazi.enable = lib.mkEnableOption "Yazi file manager";

  config = lib.mkIf cfg.enable ({
    home.packages = with pkgs; [
      yazi
    ];
  });
}
