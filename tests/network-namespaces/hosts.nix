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
    if !(c.sops.secrets ? vpn-wireguard-private-key) then
      c.my.system.services.networkNamespaces.namespaces.vpn.shared.privateKeyFile
      == "/run/my-nixos-unavailable/wireguard"
      && builtins.elem "${pkgs.coreutils}/bin/false" c.systemd.services.netns-vpn-shared.serviceConfig.ExecCondition
      && c.system.preSwitchChecks ? privateMaterial
      && (
        c.users.users.${c.my.primaryUser.name}.hashedPassword == "!"
        || c.networking.hostName == "nixos-server"
      )
    else
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
assert lib.all (
  c:
  builtins.elem "timers.target" c.systemd.timers.netns-vpn-recovery.wantedBy
  && c.systemd.services.netns-vpn-recovery.serviceConfig.Type == "oneshot"
  && lib.any (p: (p.name or "") == "vpn-status") c.environment.systemPackages
) (desktops ++ [ server ]);
assert correctSecret server;
assert server.my.system.services.networkNamespaces.namespaces.vpn.shared.role == "gateway";
assert
  server.my.system.services.networkNamespaces.namespaces.vpn.bootstrapTokenFile
  == (server.sops.secrets.hide-me-bootstrap-token.path or "/run/my-nixos-unavailable/bootstrap");
assert
  (server.sops.secrets ? hide-me-bootstrap-token)
  || builtins.elem "${pkgs.coreutils}/bin/false" server.systemd.services.hide-me-vpn.serviceConfig.ExecCondition;
assert server.systemd.services.hide-me-vpn.requires == [ ];
assert builtins.elem "netns-vpn-underlay.service" server.systemd.services.hide-me-vpn.wants;
assert server.systemd.services ? hide-me-vpn;
assert server.systemd.services ? netns-vpn-underlay;
pkgs.runCommand "shared-vpn-host-profile-checks" { } "touch $out"
