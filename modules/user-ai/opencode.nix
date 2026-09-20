{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.my.user.ai.opencode;
  agents = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  options.my.user.ai.opencode.enable = lib.mkEnableOption "OpenCode";

  config = lib.mkIf cfg.enable {
    home.packages = with agents; [
      opencode
    ];
  };
}
