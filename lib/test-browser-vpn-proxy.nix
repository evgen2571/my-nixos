# nix-build lib/test-browser-vpn-proxy.nix --no-out-link
{
  inputs ? (builtins.getFlake (toString ../.)).inputs,
  pkgs ? import inputs.nixpkgs { system = "x86_64-linux"; },
}:
pkgs.testers.runNixOSTest {
  name = "browser-vpn-proxy";
  nodes.client = { lib, ... }: {
    imports = [
      ../modules/services/network-namespaces/nixos.nix
      ../modules/services/browser-vpn-proxy.nixos.nix
    ];
    my.system.services = {
      browserVpnProxy.enable = true;
      networkNamespaces = {
        enable = true;
        namespaces.vpn = {
          enable = true;
          shared = {
            role = "client";
            endpoint = "192.0.2.1:51877";
            peers = [
              {
                publicKey = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
                allowedIPs = [
                  "0.0.0.0/0"
                  "::/0"
                ];
              }
            ];
          };
        };
      };
    };
    # Exercise the real namespace firewall/lifecycle without a provider or secrets.
    systemd.services.netns-vpn-shared.serviceConfig.ExecStart = lib.mkForce (
      pkgs.writeShellScript "test-vpn-transport" ''
        ${pkgs.iproute2}/bin/ip link add shared0 type veth peer name test-gateway
        ${pkgs.iproute2}/bin/ip link set shared0 netns vpn
        ${pkgs.iproute2}/bin/ip addr add 10.77.0.1/24 dev test-gateway
        ${pkgs.iproute2}/bin/ip link set test-gateway up
        ${pkgs.iproute2}/bin/ip -n vpn addr add 10.77.0.2/24 dev shared0
        ${pkgs.iproute2}/bin/ip -n vpn link set shared0 up
        ${pkgs.iproute2}/bin/ip -n vpn route add default dev shared0
        echo 'nameserver 10.77.0.1' > /run/network-namespaces/vpn/resolv.conf
      ''
    );
    systemd.timers.netns-vpn-recovery.wantedBy = lib.mkForce [ ];
    system.activationScripts.netns-vpn-shared-desktop-guard.text = lib.mkForce "";
    systemd.services.test-vpn-dns = {
      wantedBy = [ "multi-user.target" ];
      requires = [ "netns-vpn-shared.service" ];
      after = [ "netns-vpn-shared.service" ];
      partOf = [ "netns-vpn.service" ];
      serviceConfig = {
        ExecStart = "${pkgs.dnsmasq}/bin/dnsmasq --keep-in-foreground --conf-file=/dev/null --no-resolv --no-hosts --listen-address=10.77.0.1 --bind-interfaces --address=/selected.test/10.77.0.1 --log-queries --log-facility=-";
      };
    };
    systemd.services.test-vpn-web = {
      wantedBy = [ "multi-user.target" ];
      requires = [ "netns-vpn-shared.service" ];
      after = [ "netns-vpn-shared.service" ];
      partOf = [ "netns-vpn.service" ];
      serviceConfig = {
        ExecStart = "${pkgs.python3}/bin/python ${pkgs.writeText "test-ip-server.py" ''
          from http.server import BaseHTTPRequestHandler, HTTPServer
          class Handler(BaseHTTPRequestHandler):
              def do_GET(self):
                  self.send_response(200)
                  self.end_headers()
                  self.wfile.write(self.client_address[0].encode())
          HTTPServer(('0.0.0.0', 8000), Handler).serve_forever()
        ''}";
      };
    };
    networking.firewall.interfaces.test-gateway = {
      allowedTCPPorts = [
        53
        8000
      ];
      allowedUDPPorts = [ 53 ];
    };
    environment.systemPackages = [
      pkgs.curl
      pkgs.nftables
    ];
  };
  testScript = ''
    start_all()
    client.wait_for_unit("browser-vpn-proxy.socket")
    client.wait_for_unit("test-vpn-dns.service")
    client.wait_for_unit("test-vpn-web.service")
    direct = "curl --fail --silent --max-time 5 http://127.0.0.1:8000/"
    proxied = "curl --fail --silent --max-time 5 --socks5-hostname 127.0.0.1:1080 http://selected.test:8000/"
    client.wait_until_succeeds(direct)
    # First SOCKS request also starts both services through socket activation.
    assert client.succeed(proxied).strip() == "10.77.0.2"
    assert client.succeed(direct).strip() == "127.0.0.1"
    client.fail("getent ahostsv4 selected.test")
    client.succeed("journalctl -u test-vpn-dns | grep 'query.*selected.test'")
    client.succeed("ss -ltnH 'sport = :1080' | grep '127.0.0.1:1080'")
    client.fail("ss -ltnH 'sport = :1080' | grep -E '0.0.0.0:1080|\\[::\\]:1080'")
    client.succeed("ip netns exec vpn nft list chain inet agent_workspace output | grep 'policy drop'")
    # Simulated tunnel outage, keeping the real namespace kill switch in place.
    client.succeed("ip -n vpn link set shared0 down")
    client.fail(proxied)
    assert client.succeed(direct).strip() == "127.0.0.1"
    client.succeed("ip -n vpn link set shared0 up")
    client.wait_until_succeeds(proxied)
    client.succeed("systemctl kill --signal=SIGKILL browser-vpn-socks.service")
    client.wait_until_succeeds(proxied)
    # Namespace rebuilds must replace both processes and their namespace handles.
    client.succeed("systemctl restart netns-vpn.service")
    client.wait_until_succeeds(proxied)
    client.succeed("systemctl stop browser-vpn-proxy.socket browser-vpn-proxy.service browser-vpn-socks.service")
    client.fail(proxied)
    assert client.succeed(direct).strip() == "127.0.0.1"
    client.succeed("systemctl start browser-vpn-proxy.socket")
    client.wait_until_succeeds(proxied)
  '';
}
