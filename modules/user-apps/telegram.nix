{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.user.apps.telegram;
in
{
  options.my.user.apps.telegram.enable = lib.mkEnableOption "Telegram Desktop";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      telegram-desktop
    ];
  };
}
