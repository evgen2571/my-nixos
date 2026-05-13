{ config, lib, pkgs, ... }:

let
  cfg = config.my.user.dev.toolchains;
in
{
  options.my.user.dev.toolchains.enable = lib.mkEnableOption "developer toolchains and build tools";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      cargo
      gcc
      clang-tools
      cmake
      gnumake
      go
      python3
      uv
      zip
      nil
      nix
      nixd
      pkg-config
      luarocks
    ];
  };
}
