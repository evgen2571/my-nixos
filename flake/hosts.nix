{ inputs, withSystem, ... }:

let
  moduleProfiles = (import ../lib/module-catalog.nix { root = ../.; }).profiles;

  configPaths = import ../lib/config-paths.nix {
    root = ../.;
    lib = inputs.nixpkgs.lib;
  };

  # Assemble the system and its Home Manager user with the same inputs.
  mkHost =
    {
      hostModule,
      host,
      secretSource,
      profile,
      system ? "x86_64-linux",
      extraModules ? [ ],
      extraSpecialArgs ? { },
      requirePrivate ? false,
    }:
    withSystem system (
      { inputs', self', ... }:
      let
        packageSources = import ../lib/package-sources.nix { inherit inputs system; };

        selected = import ../lib/secret-source.nix {
          root = ../.;
          private = inputs.private;
          inherit host;
          source = secretSource;
        };

        # Pass source selection and package choices to both module systems.
        sharedSpecialArgs = {
          inherit
            inputs
            inputs'
            self'
            configPaths
            packageSources
            ;

          secretFile = selected.file;
          inherit secretSource requirePrivate host;
        }
        // extraSpecialArgs;
      in
      inputs.nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = sharedSpecialArgs;

        modules = [
          hostModule
          inputs.home-manager.nixosModules.home-manager
          inputs.sops-nix.nixosModules.sops
          ../modules/core/secrets.nixos.nix
          ../modules/deployment/nixos.nix
        ]
        ++ profile.systemModules
        ++ extraModules
        ++ selected.modules
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
      host = "pc";
      secretSource = "private";
      requirePrivate = true;
      profile = moduleProfiles.desktop;
    };

    nixos-lp = mkHost {
      hostModule = ../hosts/laptop/configuration.nix;
      host = "laptop";
      secretSource = "private";
      requirePrivate = true;
      profile = moduleProfiles.desktop;
    };

    nixos-server = mkHost {
      hostModule = ../hosts/server/configuration.nix;
      host = "server";
      secretSource = "private";
      requirePrivate = true;
      profile = moduleProfiles.server;
    };
  };
}
