{
  config,
  pkgs,
  inputs,
  ...
}:

{
  imports = [ ../xserver.nix ];

  programs.niri.enable = true;
}
