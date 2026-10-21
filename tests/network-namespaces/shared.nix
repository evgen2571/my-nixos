# Native evaluation and real service-script fixtures; no credentials or activation.
{ nixpkgs }:

let
  lib = nixpkgs.lib;

  eval = import (nixpkgs + "/nixos/lib/eval-config.nix") {
    system = "x86_64-linux";

    modules = [
      ../../modules/services/network-namespaces/nixos.nix

      ({ pkgs, ... }: {
        system.stateVersion = "26.05";
        boot.loader.grub.enable = false;

        fileSystems."/" = {
          device = "/dev/test";
          fsType = "ext4";
        };

        my.system.services.networkNamespaces = {
          enable = true;

          namespaces = {
            auth = {
              enable = true;
              bootstrapTokenFile = "/run/mock-hide-me-token";
            };

            gateway = {
              enable = true;

              shared = {
                role = "gateway";
                privateKeyFile = "/var/lib/netns-gateway-shared/private-key";

                peers = [
                  {
                    publicKey = (import ./public-keys.nix).pc;

                    allowedIPs = [
                      "10.77.0.2/32"
                      "fd77::2/128"
                    ];
                  }

                  {
                    publicKey = (import ./public-keys.nix).laptop;

                    allowedIPs = [
                      "10.77.0.3/32"
                      "fd77::3/128"
                    ];
                  }
                ];
              };
            };
          }
          // lib.genAttrs [ "pc" "laptop" ] (name: {
            enable = true;

            shared = {
              role = "client";
              privateKeyFile = "/var/lib/netns-${name}-shared/private-key";
              address = if name == "pc" then "10.77.0.2/24" else "10.77.0.3/24";
              address6 = if name == "pc" then "fd77::2/64" else "fd77::3/64";
              endpoint = "127.0.0.1:51877";

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
          });
        };
      })
    ];
  };

  c = eval.config;
  pkgs = eval.pkgs;

  clients = [
    "pc"
    "laptop"
  ];

  services = c.systemd.services;
in
assert lib.all (
  name: !(services ? "hide-me-${name}") && !(services ? "netns-${name}-underlay")
) clients;
assert services.hide-me-gateway.serviceConfig.NetworkNamespacePath == "/run/netns/gateway";
assert
  services.netns-gateway-underlay.serviceConfig.ExecStart
  == "${lib.getExe pkgs.slirp4netns} --configure --disable-host-loopback --disable-dns --enable-seccomp --netns-type=path /run/netns/gateway tap0";
assert services.netns-gateway-dns.requires == [ "netns-gateway.service" ];
assert
  services.netns-gateway-dns.unitConfig.ConditionPathExists
  == "/run/network-namespaces/gateway/transport-ready";
assert services.netns-gateway-dns.partOf == [ "netns-gateway-shared.service" ];
assert services.netns-gateway-shared.partOf == [ "netns-gateway.service" ];
assert builtins.elem "netns-gateway-dns.service" services.netns-gateway-shared.wants;
assert builtins.elem "tailscaled.service" services.netns-gateway-shared.after;
assert builtins.elem "netns-gateway.service" services.netns-gateway-shared.requires;
assert c.system.activationScripts.netns-pc-shared-desktop-guard.text != "";
assert !c.networking.nat.enable;
assert c.networking.firewall.interfaces.tailscale0.allowedUDPPorts == [ 51877 ];
assert lib.all (
  name: services."netns-${name}-health".serviceConfig.InaccessiblePaths == [ "-/run/nscd" ]
) clients;
assert lib.all (
  name: services."netns-${name}-shared".serviceConfig.Restart == "on-failure"
) clients;
{
  system = c.system.build.toplevel.drvPath;

  fixtures = pkgs.runCommand "shared-vpn-fixtures" { } (
    ''
      mkdir -p $out/bin
      ln -s ${services.netns-auth.serviceConfig.ExecStart} $out/bin/auth-init
      ln -s ${services.hide-me-auth.serviceConfig.ExecStartPre} $out/bin/auth-prepare
    ''
    + lib.concatMapStringsSep "\n" (name: ''
      ln -s ${services."netns-${name}".serviceConfig.ExecStart} $out/bin/${name}-init
      ln -s ${services."netns-${name}-shared".serviceConfig.ExecStart} $out/bin/${name}-start
    '') ([ "gateway" ] ++ clients)
  );

  tools = pkgs.buildEnv {
    name = "shared-vpn-test-tools";

    paths = with pkgs; [
      bash
      coreutils
      util-linux
      iproute2
      nftables
      wireguard-tools
      procps
      curl
      dnsmasq
      python3
      bind
    ];
  };
}
