{
  config,
  lib,
  packageSources,
  ...
}:
let
  cfg = config.my.user.ai.codegraph;
in
{
  options.my.user.ai.codegraph.enable =
    lib.mkEnableOption "CodeGraph local source graph CLI (MCP registration is mutable)";

  config = lib.mkIf cfg.enable {
    # Skillshare manages MCP registration and project settings at runtime.
    home.packages = [ packageSources.codegraph ];
  };
}
