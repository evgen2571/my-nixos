{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.my.system.dev.docker;
in
{
  options.my.system.dev.docker.enable = lib.mkEnableOption "Docker";

  config = lib.mkIf cfg.enable {
    virtualisation.docker = {
      enable = true;
      package = pkgs.docker_29;
    };
  };
}
