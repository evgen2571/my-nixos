{
  configPaths,
  config,
  pkgs,
  inputs,
  ...
}:

{
  xdg.configFile."fish".source = configPaths.coding.fishConfigDir;
}
