# Production profiles must remain server-only and use their declared SOPS secrets.
{ configurations, pkgs }:
let
  lib = pkgs.lib;
  desktops = map (name: configurations.${name}.config) [
    "nixos-pc"
    "nixos-lp"
  ];
  server = configurations.nixos-server.config;
  correctSecret =
    c:
    c.my.system.services.networkNamespaces.namespaces.vpn.shared.privateKeyFile
    == c.sops.secrets.vpn-wireguard-private-key.path
    && c.sops.secrets.vpn-wireguard-private-key.mode == "0400"
    && builtins.elem "netns-vpn-shared.service" c.sops.secrets.vpn-wireguard-private-key.restartUnits;
in
assert lib.all (
  c:
  c.my.system.services.networkNamespaces.namespaces.vpn.shared.role == "client"
  && !(c.systemd.services ? hide-me-vpn)
  && !(c.systemd.services ? netns-vpn-underlay)
  && !(c.sops.secrets ? hide-me-bootstrap-token)
  && !(lib.any (p: (p.pname or "") == "hide-me") c.environment.systemPackages)
  && c.systemd.services.netns-vpn.restartIfChanged
  && correctSecret c
) desktops;
assert correctSecret server;
assert server.my.system.services.networkNamespaces.namespaces.vpn.shared.role == "gateway";
assert
  server.my.system.services.networkNamespaces.namespaces.vpn.bootstrapTokenFile
  == server.sops.secrets.hide-me-bootstrap-token.path;
assert server.systemd.services ? hide-me-vpn;
assert server.systemd.services ? netns-vpn-underlay;
pkgs.runCommand "shared-vpn-host-profile-checks" { } "touch $out"
