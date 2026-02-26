{
  config,
  inputs,
  pkgs,
  lib,
  osConfig,
  ...
}: let
	hostname = osConfig.networking.hostName or "unknown";
in {
    home.username = "evgen2571";
    home.homeDirectory = "/home/evgen2571";

	imports = 
	[
		# wm
		../../modules/wm/noctalia.nix

		# apps
		../../modules/apps/zen-browser.nix
		../../modules/apps/obsidian.nix
		../../modules/apps/vesktop.nix
		../../modules/apps/telegram.nix
		../../modules/apps/youtube-music.nix

		# file managers
		../../modules/file-managers/dolphin.nix
		../../modules/file-managers/yazi.nix

		# coding
		../../modules/coding/ide.nix
		../../modules/coding/git.nix

	];

    home.stateVersion = "25.11";
}
