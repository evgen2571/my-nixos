{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.my.user.ai.codegraph;
  # This flake's pinned nixpkgs-unstable already contains CodeGraph.
  # Keep the executable declarative, but let Skillshare manage its MCP
  # registration and project-specific usage at runtime.
  unstable = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
{
  options.my.user.ai.codegraph.enable =
    lib.mkEnableOption "CodeGraph local source graph CLI (MCP registration is mutable)";

  config = lib.mkIf cfg.enable {
    home.packages = [ unstable.codegraph ];
  };
}
