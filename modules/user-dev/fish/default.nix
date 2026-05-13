{
  config,
  lib,
  ...
}:

let
  cfg = config.my.user.dev.fish;
in
{
  imports = [
    ./config.nix
  ];

  options.my.user.dev.fish.enable = lib.mkEnableOption "Fish user configuration";
}
