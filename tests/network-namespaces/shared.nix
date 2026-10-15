# Native evaluation and real service-script fixtures; no credentials or activation.
{ nixpkgs }:
let
  lib = nixpkgs.lib;
  eval = import (nixpkgs + "/nixos/lib/eval-config.nix") {
    system = "x86_64-linux";
    modules = [
      ../../modules/system-services/network-namespaces
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
            gateway = {
              enable = true;
              shared = {
                role = "gateway";
                peers = [
                  {
                    publicKeyFile = "/var/lib/netns-pc-shared/public-key";
                    allowedIPs = [
                      "10.77.0.2/32"
                      "fd77::2/128"
                    ];
                  }
                  {
                    publicKeyFile = "/var/lib/netns-laptop-shared/public-key";
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
              address = if name == "pc" then "10.77.0.2/24" else "10.77.0.3/24";
              address6 = if name == "pc" then "fd77::2/64" else "fd77::3/64";
              endpoint = "127.0.0.1:51877";
              peers = [
                {
                  publicKeyFile = "/var/lib/netns-gateway-shared/public-key";
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
