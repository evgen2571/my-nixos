{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.my.user.ai.orca;
  agents = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  options.my.user.ai.orca.enable = lib.mkEnableOption "Orca agent workspace";

  config = lib.mkIf cfg.enable {
    home.packages = [
      agents.orca
    ];
  };
}
