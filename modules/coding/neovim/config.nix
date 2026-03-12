{
  config,
  pkgs,
  inputs,
  ...
}:

{
  xdg.configFile."nvim/init.lua".source = ./config/init.lua;
  xdg.configFile."nvim/lua/matugen-template.lua".source = ./config/lua/matugen-template.lua;

  xdg.configFile."nvim/lua/custom".source = ./config/lua/custom;
  xdg.configFile."nvim/lua/kickstart".source = ./config/lua/kickstart;
}
