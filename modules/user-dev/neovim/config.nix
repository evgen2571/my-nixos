{
  configPaths,
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.my.user.dev.neovim;
in
{
  config = lib.mkIf cfg.enable {
    xdg.configFile."nvim/init.lua".source = configPaths.coding.neovimConfigDir + "/init.lua";
    xdg.configFile."nvim/lua/matugen-template.lua".source =
      configPaths.coding.neovimConfigDir + "/lua/matugen-template.lua";

    xdg.configFile."nvim/lua/custom".source = configPaths.coding.neovimConfigDir + "/lua/custom";
    xdg.configFile."nvim/lua/kickstart".source = configPaths.coding.neovimConfigDir + "/lua/kickstart";
  };
}
