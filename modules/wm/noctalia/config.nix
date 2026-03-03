{
  config,
  pkgs,
  inputs,
  ...
}:

{
  xdg.configFile."noctalia/settings.json".source = ./config/settings.json;
  xdg.configFile."noctalia/plugins.json".source = ./config/plugins.json;
}
