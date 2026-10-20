{
  config,
  lib,
  packageSources,
  ...
}:
let
  cfg = config.my.user.ai.opencode;
in
{
  options.my.user.ai.opencode.enable = lib.mkEnableOption "OpenCode";

  config = lib.mkIf cfg.enable {
    home.packages = [ packageSources.opencode ];
  };
}
