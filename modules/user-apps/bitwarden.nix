{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.user.apps.bitwarden;
in
{
  options.my.user.apps.bitwarden.enable = lib.mkEnableOption "Bitwarden";

  config = lib.mkIf cfg.enable ({
    home.packages = with pkgs; [
      bitwarden-desktop
      bitwarden-cli
    ];
  });
}
