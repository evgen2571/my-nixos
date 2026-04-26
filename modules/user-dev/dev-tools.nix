{ config, lib,  pkgs, ... }:

let
  cfg = config.my.user.dev.devTools;
in
{
  options.my.user.dev.devTools.enable = lib.mkEnableOption "development tools";

  config = lib.mkIf cfg.enable (
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
  );
}
