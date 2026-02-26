{ config, pkgs, lib, ... }:


{
	services.displayManager.ly.enable = true;
	services.displayManager.defaultSession = "niri";
}
