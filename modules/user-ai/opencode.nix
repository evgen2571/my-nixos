{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.user.ai.opencode;
in
{
  options.my.user.ai.opencode.enable = lib.mkEnableOption "OpenCode CLI";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      opencode
    ];
  };
}
