{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.user.apps.notion;
in
{
  options.my.user.apps.notion.enable = lib.mkEnableOption "Notion";

  config = lib.mkIf cfg.enable ({
    home.packages = with pkgs; [
      notion-app-enhanced
    ];
  });
}
