{
  configPaths,
  config,
  pkgs,
  inputs,
  ...
}:

{
  xdg.configFile."kitty/kitty.conf".source = configPaths.coding.kittyConf;
}
