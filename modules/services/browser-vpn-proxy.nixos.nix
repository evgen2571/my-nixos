{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.system.services.browserVpnProxy;
  namespaces = config.my.system.services.networkNamespaces;
  netns = "netns-${cfg.namespace}.service";
  runtime = "/run/network-namespaces/${cfg.namespace}";
in
{
  options.my.system.services.browserVpnProxy = {
    enable = lib.mkEnableOption "a loopback SOCKS5 proxy through an existing client VPN namespace";
    namespace = lib.mkOption {
      type = lib.types.strMatching "[a-zA-Z][a-zA-Z0-9_-]{0,31}";
      default = "vpn";
    };
    port = lib.mkOption {
      type = lib.types.ints.between 1024 65535;
      default = 1080;
      description = "Unprivileged loopback port on the host and inside the namespace.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion =
          namespaces.enable
          && (namespaces.namespaces.${cfg.namespace}.enable or false)
          && (namespaces.namespaces.${cfg.namespace}.killSwitch or false)
          && (namespaces.namespaces.${cfg.namespace}.shared.role or "") == "client";
        message = "browserVpnProxy requires an enabled client VPN namespace with its kill switch.";
      }
    ];

    systemd = {
      sockets.browser-vpn-proxy = {
        description = "Host loopback entry to the browser VPN proxy";
        wantedBy = [ "sockets.target" ];
        listenStreams = [ "127.0.0.1:${toString cfg.port}" ];
      };

      services = {
        browser-vpn-socks = {
          description = "SOCKS5 inside the client VPN namespace";
          requires = [ netns ];
          wants = [ "netns-${cfg.namespace}-shared.service" ];
          after = [
            netns
            "netns-${cfg.namespace}-shared.service"
          ];
          bindsTo = [ netns ];
          partOf = [ netns ];
          serviceConfig = {
            ExecStart = "${lib.getExe pkgs.microsocks} -i 127.0.0.1 -p ${toString cfg.port}";
            ExecStartPost = pkgs.writeShellScript "wait-browser-vpn-socks" ''
              for ((attempt=0; attempt<100; attempt++)); do
                if (: > /dev/tcp/127.0.0.1/${toString cfg.port}) 2>/dev/null; then
                  exit 0
                fi
                ${pkgs.coreutils}/bin/sleep 0.1
              done
              exit 1
            '';
            NetworkNamespacePath = "/run/netns/${cfg.namespace}";
            BindReadOnlyPaths = [
              "${runtime}/resolv.conf:/etc/resolv.conf"
              "${runtime}/nsswitch.conf:/etc/nsswitch.conf"
            ];
            InaccessiblePaths = [ "-/run/nscd" ];
            DynamicUser = true;
            CapabilityBoundingSet = [ ];
            NoNewPrivileges = true;
            ProtectSystem = "strict";
            ProtectHome = true;
            PrivateTmp = true;
            Restart = "on-failure";
            RestartSec = 1;
          };
        };

        browser-vpn-proxy = {
          description = "Forward the host socket into the client VPN namespace";
          requires = [ "browser-vpn-socks.service" ];
          after = [
            netns
            "browser-vpn-socks.service"
          ];
          bindsTo = [ netns ];
          partOf = [ netns ];
          serviceConfig = {
            # The inherited listener stays on the host; only outgoing sockets enter the VPN.
            ExecStart = "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd 127.0.0.1:${toString cfg.port}";
            NetworkNamespacePath = "/run/netns/${cfg.namespace}";
            DynamicUser = true;
            CapabilityBoundingSet = [ ];
            NoNewPrivileges = true;
            ProtectSystem = "strict";
            ProtectHome = true;
            PrivateTmp = true;
            Restart = "on-failure";
            RestartSec = 1;
          };
        };
      };
    };
  };
}
