{
  config,
  pkgs,
  inputs,
  ...
}:

{
  services.xserver.enable = true;
  programs.xwayland.enable = true;
  programs.niri.enable = true;
}
