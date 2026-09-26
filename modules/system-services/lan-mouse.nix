{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:

let
  cfg = config.my.system.services.lanMouse;
in
{
  options.my.system.services.lanMouse.enable = lib.mkEnableOption "Lan Mouse firewall access";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.lan-mouse
    ];

    networking.firewall.allowedUDPPorts = [ 4242 ];
  };
}
