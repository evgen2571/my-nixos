# Real systemd lifecycle and old-generation reboot tests, entirely inside VMs.
{ pkgs }:
let
  lib = pkgs.lib;
  migration = pkgs.runCommand "vpn-migration-bundle" { } ''
    mkdir -p $out
    cp ${../../modules/system-services/network-namespaces/migration}/*.sh $out/
  '';
  common = { ... }: {
    imports = [ ../../modules/system-services/network-namespaces ];
    environment.systemPackages = with pkgs; [
      wireguard-tools
      iproute2
      nftables
      bind
      curl
    ];
    environment.etc."vpn-migration".source = migration;
    systemd.services.tailscaled = {
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.coreutils}/bin/true";
      };
    };
    my.system.services.networkNamespaces = {
      enable = true;
      namespaces.vpn.enable = true;
    };
    systemd.timers.netns-vpn-health.wantedBy = lib.mkForce [ ];
  };
  mockProvider = {
    wantedBy = [ "multi-user.target" ];
    requires = [ "netns-vpn.service" ];
    after = [ "netns-vpn.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "mock-local-provider" ''
        echo started >> /var/lib/provider-starts
      '';
    };
  };
in
pkgs.testers.runNixOSTest {
  name = "shared-vpn-systemd";
  nodes = {
    server = { ... }: {
      imports = [ common ];
      networking.hostName = "nixos-server";
      networking.firewall.allowedUDPPorts = [ 51877 ]; # VM LAN models Tailscale transport.
      my.system.services.networkNamespaces.namespaces.vpn.shared = {
        role = "gateway";
        peers = [
          {
            publicKeyFile = "/var/lib/netns-vpn-shared/client.pub";
            allowedIPs = [
              "10.77.0.2/32"
              "fd77::2/128"
            ];
          }
        ];
      };
      # No provider authentication or external VPN connection in this test.
      systemd.services.hide-me-vpn = lib.mkForce { enable = false; };
      systemd.services.netns-vpn-underlay.wantedBy = lib.mkForce [ ];
      systemd.services.mock-egress = {
        wantedBy = [ "multi-user.target" ];
        requires = [ "netns-vpn.service" ];
        after = [ "netns-vpn.service" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = pkgs.writeShellScript "mock-egress" ''
            set -eu
            ${pkgs.iproute2}/bin/ip netns add external
            ${pkgs.iproute2}/bin/ip -n vpn link add hm0 type veth peer name outside
            ${pkgs.iproute2}/bin/ip -n vpn link set outside netns external
            ${pkgs.iproute2}/bin/ip -n vpn addr add 203.0.113.2/24 dev hm0
            ${pkgs.iproute2}/bin/ip -n vpn link set hm0 up
            ${pkgs.iproute2}/bin/ip -n vpn route replace default dev hm0
            ${pkgs.iproute2}/bin/ip -n external link set lo up
            ${pkgs.iproute2}/bin/ip -n external addr add 203.0.113.1/24 dev outside
            ${pkgs.iproute2}/bin/ip -n external addr add 203.0.113.3/24 dev outside
            ${pkgs.iproute2}/bin/ip -n external link set outside up
            printf 'nameserver 203.0.113.1\n' > /run/network-namespaces/vpn/resolv.conf
          '';
        };
      };
      systemd.services.mock-dns-one = {
        wantedBy = [ "multi-user.target" ];
        requires = [ "mock-egress.service" ];
        after = [ "mock-egress.service" ];
        serviceConfig = {
          NetworkNamespacePath = "/run/netns/external";
          ExecStart = "${pkgs.dnsmasq}/bin/dnsmasq --keep-in-foreground --conf-file=/dev/null --bind-interfaces --listen-address=203.0.113.1 --no-resolv --no-hosts --address=/egress.test/203.0.113.1 --pid-file=";
        };
      };
      systemd.services.mock-dns-two = {
        wantedBy = [ "multi-user.target" ];
        requires = [ "mock-egress.service" ];
        after = [ "mock-egress.service" ];
        serviceConfig = {
          NetworkNamespacePath = "/run/netns/external";
          ExecStart = "${pkgs.dnsmasq}/bin/dnsmasq --keep-in-foreground --conf-file=/dev/null --bind-interfaces --listen-address=203.0.113.3 --no-resolv --no-hosts --address=/egress.test/203.0.113.3 --pid-file=";
        };
      };
      systemd.services.mock-http = {
        wantedBy = [ "multi-user.target" ];
        requires = [ "mock-egress.service" ];
        after = [ "mock-egress.service" ];
        serviceConfig = {
          NetworkNamespacePath = "/run/netns/external";
          ExecStart = "${pkgs.python3}/bin/python3 -m http.server 8080 --bind 203.0.113.1";
        };
      };
    };
    client = { ... }: {
      imports = [ common ];
      networking.hostName = "nixos-pc";
      # Boot the pre-migration role; candidate is a test-only specialisation.
      systemd.services.hide-me-vpn = lib.mkForce mockProvider;
      specialisation.shared.configuration.my.system.services.networkNamespaces.namespaces.vpn.shared = {
        role = lib.mkForce "client";
        address = "10.77.0.2/24";
        address6 = "fd77::2/64";
        endpoint = "192.168.1.2:51877"; # Nodes are assigned addresses alphabetically.
        peers = [
          {
            publicKeyFile = "/var/lib/netns-vpn-shared/server.pub";
            allowedIPs = [
              "0.0.0.0/0"
              "::/0"
            ];
          }
        ];
      };
    };
  };
  testScript = ''
    client.start(allow_reboot=True)
    server.start()
    server.wait_for_unit("mock-http.service")
    client.wait_for_unit("multi-user.target")
    client.wait_for_unit("hide-me-vpn.service")
    assert client.succeed("cat /var/lib/provider-starts").splitlines() == ["started"]
    assert int(server.succeed("systemctl show netns-vpn-shared -p NRestarts --value").strip()) <= 2
    old = client.succeed("readlink -f /run/current-system").strip()
    candidate = client.succeed("readlink -f /run/current-system/specialisation/shared").strip()
    # Provision disposable test keys; only public keys cross nodes.
    client.succeed("install -d -m 0700 /var/lib/netns-vpn-shared; umask 077; wg genkey > /var/lib/netns-vpn-shared/private-key; wg pubkey < /var/lib/netns-vpn-shared/private-key > /var/lib/netns-vpn-shared/public-key")
    server.wait_until_succeeds("test -s /var/lib/netns-vpn-shared/public-key")
    client_key = client.succeed("cat /var/lib/netns-vpn-shared/public-key").strip()
    server_key = server.succeed("cat /var/lib/netns-vpn-shared/public-key").strip()
    assert len(client_key) == 44 and len(server_key) == 44
    server.succeed(f"printf '%s\\n' '{client_key}' > /var/lib/netns-vpn-shared/client.pub")
    client.succeed(f"printf '%s\\n' '{server_key}' > /var/lib/netns-vpn-shared/server.pub")
    # Refuse to overwrite someone else's persistent unit override.
    client.succeed("mkdir -p /etc/systemd/system.control; echo preserve-me > /etc/systemd/system.control/hide-me-vpn.service")
    client.fail("bash /etc/vpn-migration/desktop-provider-guard.sh block")
    assert client.succeed("cat /etc/systemd/system.control/hide-me-vpn.service").strip() == "preserve-me"
    client.succeed("rm /etc/systemd/system.control/hide-me-vpn.service")
    # Persistent guard does not stop the working provider by itself.
    client.succeed("bash /etc/vpn-migration/desktop-provider-guard.sh block")
    client.succeed("systemctl is-active hide-me-vpn.service")
    client.succeed("systemctl stop hide-me-vpn.service netns-vpn-health.timer netns-vpn-health.service netns-vpn-underlay.service netns-vpn.service")
    client.succeed(f"bash /etc/vpn-migration/prepare-rollback.sh {candidate} 192.168.1.2")
    client.succeed("systemctl is-active shared-vpn-rollback.timer")
    client.succeed(f"{candidate}/bin/switch-to-configuration test")
    client.succeed("systemctl start netns-vpn.service netns-vpn-shared.service")
    client.wait_for_unit("netns-vpn-shared.service")
    server.wait_until_succeeds("systemctl is-active --quiet netns-vpn-dns.service")
    probe = "ip netns exec vpn curl --noproxy '*' -fsS --max-time 3 http://203.0.113.1:8080 >/dev/null"
    dns = "ip netns exec vpn dig +short +time=1 +tries=1 @10.77.0.1 egress.test"
    client.wait_until_succeeds(probe)
    client.wait_until_succeeds(dns + " | grep -x 203.0.113.1")
    assert server.succeed("systemctl show netns-vpn-dns -p User --value").strip() == "dnsmasq"
    # DNS follows provider resolver changes and has no cached fallback.
    server.succeed("printf 'nameserver 203.0.113.3\\n' > /run/network-namespaces/vpn/resolv.conf")
    client.wait_until_succeeds(dns + " | grep -x 203.0.113.3")
    server.succeed("systemctl stop mock-dns-two")
    client.wait_until_fails(dns + " | grep -x 203.0.113.3")
    server.succeed("systemctl start mock-dns-two")
    client.wait_until_succeeds(dns + " | grep -x 203.0.113.3")
    # Shared restart must restart its bound DNS service too.
    server.succeed("systemctl restart netns-vpn-shared")
    server.wait_until_succeeds("systemctl is-active --quiet netns-vpn-dns.service")
    client.wait_until_succeeds(probe)
    client.wait_until_succeeds(dns + " | grep -x 203.0.113.3")
    # Namespace restart must propagate to the client transport and private DNS.
    client.succeed("systemctl restart netns-vpn")
    client.wait_for_unit("netns-vpn-shared.service")
    client.wait_until_succeeds(probe)
    client.wait_until_succeeds(dns + " | grep -x 203.0.113.3")
    # Simulated Tailscale UDP outage must recover without transport recreation.
    server.succeed("iptables -I INPUT -p udp --dport 51877 -j DROP")
    client.fail(probe)
    server.succeed("iptables -D INPUT -p udp --dport 51877 -j DROP")
    client.wait_until_succeeds(probe)
    # Retained process must lose egress when independent rollback runs.
    before = client.succeed("stat -Lc %i /run/netns/vpn").strip()
    client.succeed("ip netns exec vpn sleep 300 >/dev/null 2>&1 & echo $! > /run/old-app-pid")
    client.succeed("systemctl start shared-vpn-rollback.service")
    client.fail("systemctl is-active --quiet shared-vpn-rollback.timer")
    client.wait_for_unit("netns-vpn.service")
    assert client.succeed("readlink -f /run/current-system").strip() == old
    assert client.succeed("stat -Lc %i /run/netns/vpn").strip() != before
    client.fail("ip -n vpn link show shared0")
    client.fail("systemctl start hide-me-vpn.service")
    client.fail("nsenter --net=/proc/$(cat /run/old-app-pid)/ns/net ip link show shared0")
    # Reboot really returns to the OLD standalone image, whose activation lacks the guard.
    client.reboot()
    client.wait_for_unit("multi-user.target")
    assert client.succeed("readlink -f /run/current-system").strip() == old
    assert client.succeed("systemctl show hide-me-vpn.service -p LoadState --value").strip() == "masked"
    client.fail("systemctl start hide-me-vpn.service")
    assert client.succeed("cat /var/lib/provider-starts").splitlines() == ["started"]
    # Explicit operator recovery after stopping the mock gateway is reversible.
    server.succeed("systemctl stop netns-vpn-shared")
    client.succeed("bash /etc/vpn-migration/desktop-provider-guard.sh unblock")
    client.succeed("systemctl start hide-me-vpn.service")
    assert client.succeed("cat /var/lib/provider-starts").splitlines() == ["started", "started"]
  '';
}
