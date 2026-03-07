{ config, pkgs, lib, inputs,... }:

{
  nixpkgs.overlays = [ inputs.millennium.overlays.default ];

  programs.gamescope.enable = true;
  programs.steam = {
    enable = true;
	gamescopeSession.enable = true;
    package = pkgs.millennium-steam;
  };

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
	  "steam"
		  "steam-original"
		  "steam-unwrapped"
		  "steam-run"
  ];
}
