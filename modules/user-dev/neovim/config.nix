{
  configPaths,
  config,
  lib,
  ...
}:

let
  cfg = config.my.user.dev.neovim;
  nvimConfig = configPaths.dev.neovim.configDir;
in
{
  config = lib.mkIf cfg.enable {
    xdg.configFile."nvim/init.lua".source =
      nvimConfig + "/init.lua";

    xdg.configFile."nvim/lua/matugen-template.lua".source =
      nvimConfig + "/lua/matugen-template.lua";

    xdg.configFile."nvim/lua/custom".source =
      nvimConfig + "/lua/custom";

    xdg.configFile."nvim/lua/kickstart".source =
      nvimConfig + "/lua/kickstart";
  };
}
