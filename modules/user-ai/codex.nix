{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.my.user.ai.codex;
  agents = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  options.my.user.ai.codex.enable = lib.mkEnableOption "Codex CLI";

  config = lib.mkIf cfg.enable {
    home.packages = with agents; [
      codex
    ];
  };
}
