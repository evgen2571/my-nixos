{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.user.apps.slack;
in
{
  options.my.user.apps.slack.enable = lib.mkEnableOption "Slack desktop application";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      slack
    ];
  };
}
