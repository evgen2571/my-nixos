{ inputs, withSystem, ... }:
let
  wm = "niri";
  modulePaths = import ../lib/module-paths.nix { root = ../.; };
  configPaths = import ../lib/config-paths.nix { root = ../.; };
  profileImports = import ../lib/profile-imports.nix { inherit modulePaths; };
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
            wm
            modulePaths
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
            home-manager.users.operator = import ../home/operator/home.nix;
          }
        ];
      }
    );
in
{
  flake.nixosConfigurations = {
    nixos-pc = mkHost {
      hostModule = ../hosts/pc/configuration.nix;
      profile = profileImports.desktop;
    };

    nixos-lp = mkHost {
      hostModule = ../hosts/laptop/configuration.nix;
      profile = profileImports.desktop;
    };

    nixos-server = mkHost {
      hostModule = ../hosts/server/configuration.nix;
      profile = profileImports.server;
      extraModules = [ inputs.hermes-agent.nixosModules.default ];
    };
  };
}
