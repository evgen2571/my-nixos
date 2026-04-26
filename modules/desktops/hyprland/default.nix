{ ... }:

{
  imports = [ ../xserver.nix ];

  programs.hyprland = {
    enable = true;
  };
}
