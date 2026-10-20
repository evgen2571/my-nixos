{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.user.dev.zed;
in
{
  options.my.user.dev.zed.enable = lib.mkEnableOption "Zed editor";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      zed-editor
    ];
  };
}
