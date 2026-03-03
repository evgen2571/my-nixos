{ pkgs, inputs, ... }:
{
    imports = [
      inputs.noctalia.homeModules.default
	  ./config.nix
    ];

    # configure options
    programs.noctalia-shell = {
      enable = true;
    };
}
