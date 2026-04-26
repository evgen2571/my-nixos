{ pkgs, ... }:

{
  home.packages = with pkgs; [
    kdePackages.qtsvg
	kdePackages.kio
	kdePackages.kio-fuse
	kdePackages.kio-extras
	kdePackages.dolphin
  ];
}
