# Real systemd lifecycle and old-generation reboot tests, entirely inside VMs.
{ pkgs, sopsNix }:
let
  lib = pkgs.lib;
  migration = pkgs.runCommand "vpn-migration-bundle" { } ''
    mkdir -p $out
    cp ${../../modules/system-services/network-namespaces/migration}/*.sh $out/
  '';
  common = { config, ... }: {
    imports = [
      ../../modules/system-services/network-namespaces
      sopsNix.nixosModules.sops
    ];
    # The encrypted fixture is created inside each VM; no test private key enters the store.
    sops = {
      validateSopsFiles = false;
      useSystemdActivation = true;
      age.keyFile = "/var/lib/test-vpn/age-key";
      secrets.vpn-wireguard-private-key = {
        sopsFile = "/var/lib/test-vpn/secrets.yaml";
        key = "wireguard_private_key";
        mode = "0400";
        restartUnits = [ "netns-vpn-shared.service" ];
      };
    };
    systemd.services.test-vpn-secrets = {
      before = [ "sops-install-secrets.service" ];
      after = [ "local-fs.target" ];
      unitConfig.DefaultDependencies = false;
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "test-vpn-secrets" ''
          set -eu
          umask 077
          ${pkgs.coreutils}/bin/mkdir -p /var/lib/test-vpn
          if [[ ! -s /var/lib/test-vpn/age-key ]]; then
            ${pkgs.age}/bin/age-keygen -o /var/lib/test-vpn/age-key
            recipient=$(${pkgs.age}/bin/age-keygen -y /var/lib/test-vpn/age-key)
            # Deliberately public mock seeds match public-keys.nix.
            ${pkgs.python3}/bin/python3 -c 'import base64,json; print(json.dumps({"wireguard_private_key":base64.b64encode(bytes([${
              if config.networking.hostName == "nixos-server" then
                "1"
              else if config.networking.hostName == "nixos-lp" then
                "3"
              else
                "2"
            }])*32).decode()}))' |
              ${pkgs.sops}/bin/sops --encrypt --age "$recipient" --input-type json --output-type yaml /dev/stdin > /var/lib/test-vpn/secrets.yaml
          fi
        '';
      };
    };
    systemd.services.sops-install-secrets = {
      requires = [ "test-vpn-secrets.service" ];
      after = [ "test-vpn-secrets.service" ];
    };
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
    # No external HTTPS/provider/Tailscale dependency in this isolated LAN fixture.
    systemd.timers.netns-vpn-recovery.wantedBy = lib.mkForce [ ];
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
      networking.interfaces.eth1.ipv4.addresses = [
        {
          address = "192.168.1.254";
          prefixLength = 24;
        }
      ];
      networking.firewall.allowedUDPPorts = [ 51877 ]; # VM LAN models Tailscale transport.
      my.system.services.networkNamespaces.namespaces.vpn.shared = {
        role = "gateway";
        peers = [
          {
            publicKey = (import ./public-keys.nix).laptop;
            allowedIPs = [
              "10.77.0.3/32"
              "fd77::3/128"
            ];
          }
          {
            publicKey = (import ./public-keys.nix).pc;
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
    laptop = { ... }: {
      imports = [ common ];
      networking.hostName = "nixos-lp";
      my.system.services.networkNamespaces.namespaces.vpn.shared = {
        role = "client";
        address = "10.77.0.3/24";
        address6 = "fd77::3/64";
        endpoint = "192.168.1.254:51877";
        peers = [
          {
            publicKey = (import ./public-keys.nix).gateway;
            allowedIPs = [
              "0.0.0.0/0"
              "::/0"
            ];
          }
        ];
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
        endpoint = "192.168.1.254:51877";
        peers = [
          {
            publicKey = (import ./public-keys.nix).gateway;
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
    laptop.start(allow_reboot=True)
    server.wait_for_unit("mock-http.service")
    client.wait_for_unit("multi-user.target")
    client.wait_for_unit("hide-me-vpn.service")
    assert client.succeed("cat /var/lib/provider-starts").splitlines() == ["started"]
    assert int(server.succeed("systemctl show netns-vpn-shared -p NRestarts --value").strip()) == 0
    old = client.succeed("readlink -f /run/current-system").strip()
    candidate = client.succeed("readlink -f /run/current-system/specialisation/shared").strip()
    client.succeed("test -s /run/secrets/vpn-wireguard-private-key; test $(stat -Lc %a /run/secrets/vpn-wireguard-private-key) = 400")
    # Refuse to overwrite someone else's persistent unit override.
    client.succeed("mkdir -p /etc/systemd/system.control; echo preserve-me > /etc/systemd/system.control/hide-me-vpn.service")
    client.fail("bash /etc/vpn-migration/desktop-provider-guard.sh")
    assert client.succeed("cat /etc/systemd/system.control/hide-me-vpn.service").strip() == "preserve-me"
    client.succeed("rm /etc/systemd/system.control/hide-me-vpn.service")
    # Permanent desktop disable stops both provider and underlay.
    client.succeed("bash /etc/vpn-migration/desktop-provider-guard.sh")
    client.fail("systemctl is-active --quiet hide-me-vpn.service")
    client.fail("systemctl is-active --quiet netns-vpn-underlay.service")
    client.succeed(f"bash /etc/vpn-migration/prepare-rollback.sh {candidate} 192.168.1.254")
    client.succeed("systemctl is-active shared-vpn-rollback.timer")
    client.succeed(f"{candidate}/bin/switch-to-configuration test")
    client.wait_for_unit("netns-vpn-shared.service")
    server.wait_until_succeeds("systemctl is-active --quiet netns-vpn-dns.service")
    probe = "ip netns exec vpn curl --noproxy '*' -fsS --max-time 3 http://203.0.113.1:8080 >/dev/null"
    dns = "ip netns exec vpn dig +short +time=1 +tries=1 @10.77.0.1 egress.test"
    try:
        client.wait_until_succeeds(probe, timeout=45)
        laptop.wait_until_succeeds(probe, timeout=45)
    except Exception:
        for machine in [client, laptop, server]:
            print(machine.succeed("ip -brief address; ip route; ip -n vpn route show table all; ip netns exec vpn wg show shared0 public-key; ip netns exec vpn wg show shared0 endpoints; ip netns exec vpn wg show shared0 latest-handshakes; ip netns exec vpn nft list table inet agent_workspace"))
        raise
    client.wait_until_succeeds(dns + " | grep -x 203.0.113.1")
    # A fresh marker must never bypass fresh independent filter checks.
    client.succeed("date +%s > /run/network-namespaces/vpn/ready; /etc/network-namespaces/vpn-check")
    client.succeed("ip netns exec vpn nft 'chain inet agent_workspace forward { policy accept; }'")
    client.fail("/etc/network-namespaces/vpn-check")
    client.succeed("ip netns exec vpn nft 'chain inet agent_workspace forward { policy drop; }'")
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
    client.succeed("ip netns exec vpn sleep 300 >/dev/null 2>&1 & echo $! > /run/old-app-pid")
    client.succeed("systemctl start shared-vpn-rollback.service")
    client.fail("systemctl is-active --quiet shared-vpn-rollback.timer")
    assert client.succeed("readlink -f /run/current-system").strip() == old
    client.fail("test -e /run/netns/vpn")
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
    assert client.succeed("systemctl show netns-vpn-underlay.service -p LoadState --value").strip() == "masked"
    client.fail("systemctl start netns-vpn-underlay.service")
    # Normal client reboot automatically decrypts SOPS and starts only the overlay.
    laptop.reboot()
    laptop.wait_for_unit("netns-vpn-shared.service")
    laptop.succeed("systemctl start netns-vpn-recovery.service")
    laptop.succeed("vpn-status --verbose | grep 'VPN:'")
    laptop.succeed("test -s /var/lib/network-namespaces-vpn/status.json")
    laptop.wait_until_succeeds(probe)
    for unit in ["hide-me-vpn.service", "netns-vpn-underlay.service"]:
        assert laptop.succeed(f"systemctl show {unit} -p LoadState --value").strip() == "masked"
  '';
}
