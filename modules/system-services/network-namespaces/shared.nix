{
  config,
  lib,
  pkgs,
  ...
}:
let
  active = lib.filterAttrs (
    _: ns: ns.enable && ns.shared.role != "standalone"
  ) config.my.system.services.networkNamespaces.namespaces;
  instances = lib.mapAttrs (
    name: ns:
    let
      gateway = ns.shared.role == "gateway";
      unit = "netns-${name}-shared";
      runtime = "/run/network-namespaces/${name}";
      state = "/var/lib/${unit}";
      start = pkgs.writeShellApplication {
        name = "${unit}-start";
        runtimeInputs = with pkgs; [
          coreutils
          iproute2
          wireguard-tools
          procps
        ];
        text = ''
          umask 077
          if [[ ! -s ${state}/private-key ]]; then
            wg genkey > ${state}/private-key.new
            mv ${state}/private-key.new ${state}/private-key
          fi
          chmod 0600 ${state}/private-key
          wg pubkey < ${state}/private-key > ${state}/public-key
          ${lib.concatMapStringsSep "\n" (
            peer: "test -s ${lib.escapeShellArg peer.publicKeyFile}"
          ) ns.shared.peers}
          # WireGuard's UDP socket stays in its birth namespace (the host).
          ip -n ${name} link delete shared0 2>/dev/null || true
          transport="svpn$$"
          ip link add "$transport" type wireguard
          trap 'ip link delete "$transport" 2>/dev/null || true' EXIT
          wg set "$transport" private-key ${state}/private-key ${lib.optionalString gateway "listen-port 51877"}
          ${lib.concatMapStringsSep "\n" (peer: ''
            wg set "$transport" peer "$(cat ${lib.escapeShellArg peer.publicKeyFile})" allowed-ips ${lib.escapeShellArg (lib.concatStringsSep "," peer.allowedIPs)} ${
              lib.optionalString (!gateway) "endpoint ${ns.shared.endpoint} persistent-keepalive 25"
            }
          '') ns.shared.peers}
          ip link set "$transport" netns ${name}
          ip -n ${name} link set "$transport" name shared0
          trap - EXIT
          ip -n ${name} address add ${lib.escapeShellArg ns.shared.address} dev shared0
          ip -n ${name} -6 address add ${lib.escapeShellArg ns.shared.address6} dev shared0
          ip -n ${name} link set shared0 mtu 1280 up
          ${
            if gateway then
              ''
                for family in -4 -6; do
                  prefix=10.77.0.0/24
                  [[ "$family" == -4 ]] || prefix=fd77::/64
                  while ip -n ${name} "$family" rule delete priority 9 2>/dev/null; do :; done
                  ip -n ${name} "$family" rule add priority 9 to "$prefix" lookup main
                done
                ip netns exec ${name} sysctl -qw net.ipv4.ip_forward=1 net.ipv6.conf.all.forwarding=1
              ''
            else
              ''
                ip -n ${name} route replace default dev shared0
                ip -n ${name} -6 route replace default dev shared0
                printf 'nameserver 10.77.0.1\noptions timeout:2 attempts:2\n' > ${runtime}/resolv.conf
              ''
          }
        '';
      };
    in
    {
      assertions = [
        {
          assertion =
            ns.shared.peers != [ ]
            && (gateway || (builtins.length ns.shared.peers == 1 && ns.shared.endpoint != null))
            && lib.all (
              p:
              lib.hasPrefix "/" p.publicKeyFile
              && !lib.hasPrefix "/nix/store/" p.publicKeyFile
              && p.allowedIPs != [ ]
            ) ns.shared.peers;
          message = "Shared VPN ${name} requires runtime peer keys and allowed IPs (one peer and an endpoint for clients).";
        }
      ];
      systemd.services.${unit} = {
        description = "Tailscale transport for shared VPN ${name}";
        wantedBy = [ "multi-user.target" ];
        requires = [ "netns-${name}.service" ];
        wants = [ "tailscaled.service" ] ++ lib.optional gateway "netns-${name}-dns.service";
        after = [
          "netns-${name}.service"
          "tailscaled.service"
        ];
        bindsTo = [ "netns-${name}.service" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          NoNewPrivileges = true;
          CapabilityBoundingSet = [
            "CAP_NET_ADMIN"
            "CAP_SYS_ADMIN"
          ];
          StateDirectory = unit;
          StateDirectoryMode = "0700";
          ExecStart = lib.getExe start;
          ExecStop = "-${pkgs.iproute2}/bin/ip -n ${name} link delete shared0";
          ExecStopPost = "${pkgs.coreutils}/bin/rm -f ${runtime}/ready";
          Restart = "on-failure";
          RestartSec = 10;
        };
        unitConfig.StartLimitIntervalSec = 0;
      };
      systemd.services."netns-${name}-dns" = lib.mkIf gateway {
        description = "VPN-only DNS for shared clients";
        wantedBy = [ "multi-user.target" ];
        requires = [ "${unit}.service" ];
        after = [ "${unit}.service" ];
        bindsTo = [ "${unit}.service" ];
        serviceConfig = {
          ExecStart = "${pkgs.dnsmasq}/bin/dnsmasq --keep-in-foreground --conf-file=/dev/null --interface=shared0 --bind-interfaces --listen-address=10.77.0.1 --resolv-file=${runtime}/resolv.conf --no-hosts --cache-size=0 --pid-file=";
          User = "dnsmasq";
          Group = "dnsmasq";
          NoNewPrivileges = true;
          AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
          CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];
          NetworkNamespacePath = "/run/netns/${name}";
          ProtectSystem = "strict";
          ProtectHome = true;
          PrivateTmp = true;
          InaccessiblePaths = [ "-/run/nscd" ];
          Restart = "always";
          RestartSec = 3;
        };
      };
    }
  ) active;
in
{
  config = lib.mkIf config.my.system.services.networkNamespaces.enable {
    assertions = lib.concatMap (instance: instance.assertions) (lib.attrValues instances);
    systemd.services = lib.mkMerge (
      map (instance: instance.systemd.services) (lib.attrValues instances)
    );
    users.users.dnsmasq = lib.mkIf (lib.any (ns: ns.shared.role == "gateway") (lib.attrValues active)) {
      isSystemUser = true;
      group = "dnsmasq";
    };
    users.groups.dnsmasq = lib.mkIf (lib.any (ns: ns.shared.role == "gateway") (
      lib.attrValues active
    )) { };
    networking.firewall.interfaces.tailscale0.allowedUDPPorts = lib.optional (lib.any (
      ns: ns.shared.role == "gateway"
    ) (lib.attrValues active)) 51877;
  };
}
