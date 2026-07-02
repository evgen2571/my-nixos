{ inputs, withSystem, ... }:
let
  moduleProfiles = (import ../lib/module-catalog.nix { root = ../.; }).profiles;
  configPaths = import ../lib/config-paths.nix { root = ../.; };
  mkHost =
    {
      hostModule,
      profile,
      system ? "x86_64-linux",
      extraModules ? [ ],
      extraSpecialArgs ? { },
    }:
    withSystem system (
      { inputs', self', ... }:
      let
        sharedSpecialArgs = {
          inherit
            inputs
            inputs'
            self'
            configPaths
            ;
        }
        // extraSpecialArgs;
      in
      inputs.nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = sharedSpecialArgs;
        modules = [
          hostModule
          inputs.home-manager.nixosModules.home-manager
        ]
        ++ profile.systemModules
        ++ extraModules
        ++ [
          {
            home-manager.backupFileExtension = "backup";
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = sharedSpecialArgs;
            home-manager.sharedModules = profile.homeModules;
          }
        ];
      }
    );
in
{
  flake.nixosConfigurations = {
    nixos-pc = mkHost {
      hostModule = ../hosts/pc/configuration.nix;
      profile = moduleProfiles.desktop;
    };

    nixos-lp = mkHost {
      hostModule = ../hosts/laptop/configuration.nix;
      profile = moduleProfiles.desktop;
    };

    nixos-server = mkHost {
      hostModule = ../hosts/server/configuration.nix;
      profile = moduleProfiles.server;
      extraModules = [ inputs.hermes-agent.nixosModules.default ];
    };
  };
}
