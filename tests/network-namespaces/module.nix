# Focused native NixOS evaluation, independent of desktop/GPU package builds.
{ nixpkgs }:

let
  base = {
    system.stateVersion = "26.05";
    boot.loader.grub.enable = false;

    fileSystems."/" = {
      device = "/dev/test";
      fsType = "ext4";
    };
  };

  evaluate =
    modules:
    import (nixpkgs + "/nixos/lib/eval-config.nix") {
      system = "x86_64-linux";
      inherit modules;
    };

  baseline = (evaluate [ base ]).config;

  eval = evaluate [
    base
    ../../modules/system-services/network-namespaces

    ({ pkgs, ... }: {
      users.users.probe.isNormalUser = true;

      my.system.services.networkNamespaces = {
        enable = true;
        namespaces.vpn.enable = true;

        applications.probe = {
          namespace = "vpn";
          user = "probe";
          package = pkgs.hello;
        };
      };
    })
  ];

  c = eval.config;
in
assert !c.networking.nat.enable;
assert c.networking.firewall.extraCommands == baseline.networking.firewall.extraCommands;
assert c.networking.nftables.ruleset == baseline.networking.nftables.ruleset;
assert c.systemd.services.hide-me-vpn.serviceConfig.NetworkNamespacePath == "/run/netns/vpn";
assert c.systemd.services.hide-me-vpn.serviceConfig.User == "root";
assert builtins.elem "netns-vpn.service" c.systemd.services.netns-vpn-underlay.requires;
assert builtins.any (
  rule: builtins.any (cmd: builtins.elem "NOSETENV" cmd.options) rule.commands
) c.security.sudo.extraRules;
{
  system = c.system.build.toplevel.drvPath;
  launcher = c.my.system.services.networkNamespaces.launcherPackage;

  units = map (name: c.systemd.units.${name}.unit) [
    "netns-vpn.service"
    "netns-vpn-underlay.service"
    "hide-me-vpn.service"
    "netns-vpn-health.service"
  ];
}
