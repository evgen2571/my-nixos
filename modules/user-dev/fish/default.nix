{ lib, ... }:

{
  imports = [
    ./config.nix
  ];

  options.my.user.dev.fish.enable = lib.mkEnableOption "Fish user configuration";
}
