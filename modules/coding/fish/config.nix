{
  config,
  pkgs,
  inputs,
  ...
}:

{
  xdg.configFile."fish".source = ./config;
}
