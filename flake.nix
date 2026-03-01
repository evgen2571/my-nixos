{
  description = "Flake";
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
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

	millennium.url = "github:SteamClientHomebrew/Millennium?dir=packages/nix";
  };

  outputs = inputs @{
      nixpkgs,
	  home-manager,
      ...
    }: let
      wm = "hyprland";
      mkHost = hostModule: nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
		specialArgs = {inherit inputs wm;};
        modules = [
          hostModule
		  home-manager.nixosModules.home-manager
		  {
		  	home-manager.useGlobalPkgs = true;
			home-manager.useUserPackages = true;
			home-manager.extraSpecialArgs = {inherit inputs wm;};
			home-manager.users.operator = import ./home/operator/home.nix;
		  }
        ];
      };
    in {
      nixosConfigurations = {
        nixos-pc = mkHost ./hosts/pc/configuration.nix;
        nixos-lp = mkHost ./hosts/laptop/configuration.nix;
      };
    };

}
