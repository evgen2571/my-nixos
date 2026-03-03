{ pkgs, ... }:

{
  home.packages = with pkgs; [
    cargo
    gcc
    cmake
    gnumake
    go
    python3
    uv
    curl
    zip
    unzip
	nil
	nix
	nixd
  ];
}
