{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.user.ai.skillshare;
in
{
  options.my.user.ai.skillshare.enable =
    lib.mkEnableOption "Skillshare CLI for managing AI agent resources at runtime";

  config = lib.mkIf cfg.enable {
    # Install only the executable. Skillshare's skill/MCP/plugin selections are
    # intentionally mutable and never written by Home Manager.
    home.packages = [ (pkgs.callPackage ../../pkgs/skillshare.nix { }) ];
  };
}
