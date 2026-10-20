{ config, lib, ... }:

let
  cfg = config.my.server.ssh;
in
{
  options.my.server.ssh = {
    enable = lib.mkEnableOption "hardened SSH server";

    port = lib.mkOption {
      type = lib.types.port;
      default = 22;
      description = "SSH port number.";
    };

    openOnLan = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        When true, open the SSH port on the general host firewall.

        This makes SSH reachable through ordinary non-loopback interfaces,
        subject to upstream routing and firewalls. It is NOT a guarantee
        that only a private LAN can reach it.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.openssh = {
      enable = true;
      openFirewall = false;
      ports = [ cfg.port ];

      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PubkeyAuthentication = true;

        X11Forwarding = false;
        AllowAgentForwarding = false;

        # AllowTcpForwarding is kept true to permit deliberate SSH tunnels
        # for localhost-only administration interfaces.
        AllowTcpForwarding = true;

        MaxAuthTries = 3;
        LoginGraceTime = 30;
      };
    };

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openOnLan (lib.mkAfter [ cfg.port ]);

    networking.firewall.interfaces.tailscale0.allowedTCPPorts = (lib.mkAfter [ cfg.port ]);
  };
}
