{
  description = "Flake";
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hermes-agent = {
      url = "github:NousResearch/hermes-agent";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    inputs@{
      nixpkgs,
      home-manager,
      hermes-agent,
      ...
    }:
    let
      wm = "niri";
      modulePaths = import ./lib/module-paths.nix { root = ./.; };
      configPaths = import ./lib/config-paths.nix { root = ./.; };
      mkHost =
        hostModule:
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit
              inputs
              wm
              modulePaths
              configPaths
              ;
          };
          modules = [
            hostModule
            hermes-agent.nixosModules.default
            home-manager.nixosModules.home-manager
            {
              home-manager.backupFileExtension = "backup";
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = {
                inherit
                  inputs
                  wm
                  modulePaths
                  configPaths
                  ;
              };
              home-manager.users.operator = import ./home/operator/home.nix;
            }
          ];
        };
    in
    {
      nixosConfigurations = {
        nixos-pc = mkHost ./hosts/pc/configuration.nix;
        nixos-lp = mkHost ./hosts/laptop/configuration.nix;
        nixos-server = mkHost ./hosts/server/configuration.nix;
      };
    };

}
