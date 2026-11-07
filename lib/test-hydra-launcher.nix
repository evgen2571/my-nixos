# Run: nix eval --impure --file lib/test-hydra-launcher.nix
let
  flake = builtins.getFlake (toString ../.);
  lib = flake.inputs.nixpkgs.lib;
  enabled = flake.nixosConfigurations.nixos-pc;
  disabled = enabled.extendModules {
    modules = [ { my.system.apps.hydraLauncher.enable = lib.mkForce false; } ];
  };
  hydraPackages =
    host:
    builtins.filter (p: (p.pname or "") == "hydralauncher") host.config.environment.systemPackages;
  package = builtins.head (hydraPackages enabled);
  steamProton = builtins.head enabled.config.programs.steam.extraCompatPackages;
  service = enabled.config.systemd.services.game-storage;
in
assert builtins.length (hydraPackages enabled) == 1;
assert hydraPackages disabled == [ ];
assert
  package.profile == ''
    export PROTONPATH=${steamProton.steamcompattool}
  '';
assert builtins.isString package.drvPath;
assert builtins.all (path: lib.hasInfix path service.preStart) [
  "/games/hydra/downloads"
  "/games/hydra/installed"
  "/games/hydra/prefixes"
];
assert !(lib.hasInfix "/games/hydra" disabled.config.systemd.services.game-storage.preStart);
assert service.unitConfig.RequiresMountsFor == [ "/games" ];
assert service.unitConfig.ConditionPathIsMountPoint == "/games";
"Hydra enable/disable, shared Proton, derivation, and guarded PC storage checks passed"
