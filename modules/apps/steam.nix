{ config, pkgs, lib, inputs,... }:

{
  hardware.graphics.enable = true;
  programs.steam.gamescopeSession.enable = true;

  nixpkgs.overlays = [ inputs.millennium.overlays.default ];

  programs.steam = {
    enable = true;
    package = pkgs.millennium-steam;
  };
  programs.gamescope.enable = true;

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
	  "steam"
		  "steam-original"
		  "steam-unwrapped"
		  "steam-run"
  ];
}
