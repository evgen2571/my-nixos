{
  config,
  pkgs,
  inputs,
  ...
}:

{
  services.xserver.enable = true;
  programs.xwayland.enable = true;
  programs.niri.enable = true;

	#  imports = [
	# ./outputs.nix
	# ./workspaces.nix
	# ./input.nix
	# ./startup.nix
	# ./binds.nix
	#  ];

}
