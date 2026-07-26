{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.user.apps.chrome;
in
{
  options.my.user.apps.chrome.enable = lib.mkEnableOption "Google Chrome";

  config = lib.mkIf cfg.enable ({
    home.packages = with pkgs; [
      google-chrome
    ];
  });
}
