{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.user.dev.vscode;
in
{
  options.my.user.dev.vscode.enable = lib.mkEnableOption "Visual Studio Code";

  config = lib.mkIf cfg.enable ({
    home.packages = with pkgs; [
      vscode
    ];
  });
}
