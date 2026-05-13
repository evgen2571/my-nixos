{ lib,  config, pkgs, ... }:

let
  cfg = config.my.system.services.tailscale;
in
{
  options.my.system.services.tailscale.enable = lib.mkEnableOption "Tailscale";

  config = lib.mkIf cfg.enable (
    {
      services.tailscale.enable = true;
    }
  );
}
