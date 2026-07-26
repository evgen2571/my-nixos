{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.user.dev.github;
in
{
  options.my.user.dev.github.enable = lib.mkEnableOption "GitHub CLI";

  config = lib.mkIf cfg.enable ({
    home.packages = with pkgs; [
      gh
    ];
  });
}
