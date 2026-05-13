{
  configPaths,
  config,
  lib,
  ...
}:

let
  cfg = config.my.user.dev.neovim;
in
{
  config = lib.mkIf cfg.enable {
    xdg.configFile."nvim/init.lua".source = configPaths.dev.neovim.configDir + "/init.lua";
    xdg.configFile."nvim/lua/matugen-template.lua".source =
      configPaths.dev.neovim.configDir + "/lua/matugen-template.lua";

    xdg.configFile."nvim/lua/custom".source = configPaths.dev.neovim.configDir + "/lua/custom";
    xdg.configFile."nvim/lua/kickstart".source = configPaths.dev.neovim.configDir + "/lua/kickstart";
  };
}
