{
  lib,
  config,
  ...
}:
let
  cfg = config.my.system.services.tailscale;
in
{
  options.my.system.services.tailscale = {
    enable = lib.mkEnableOption "Tailscale";

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to open Tailscale's UDP transport port through the
        general host firewall.

        This does not trust the tailscale0 interface and does not expose
        arbitrary application ports. Services must still allow their
        required ports explicitly on tailscale0.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.tailscale = {
      enable = true;
      openFirewall = cfg.openFirewall;
    };
  };
}
