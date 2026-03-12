{
  config,
  pkgs,
  inputs,
  ...
}:

{
  xdg.configFile."kitty/kitty.conf".source = ./kitty.conf;
}
