{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.user.apps.ciscoPacketTracer;
in
{
  options.my.user.apps.ciscoPacketTracer.enable = lib.mkEnableOption "Cisco Packet Tracer";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      cisco-packet-tracer_9
    ];
  };
}
