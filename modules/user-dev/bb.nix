{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:

let
  cfg = config.my.user.dev.bb;
in
{
  options.my.user.dev.bb.enable = lib.mkEnableOption "bb";

  config = lib.mkIf cfg.enable {
    home.packages = [
      inputs.llm-agents.packages.${pkgs.system}.bb-app
    ];
  };
}
