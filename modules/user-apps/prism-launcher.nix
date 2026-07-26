{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.user.apps.prismLauncher;
in
{
  options.my.user.apps.prismLauncher.enable = lib.mkEnableOption "Prism Launcher";

  config = lib.mkIf cfg.enable ({
    home.packages = with pkgs; [
      prismlauncher
    ];
  });
}
