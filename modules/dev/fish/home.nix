{
  config,
  configPaths,
  lib,
  ...
}:

let
  cfg = config.my.user.dev.fish;
in
{
  options.my.user.dev.fish.enable = lib.mkEnableOption "Fish user configuration";

  config = lib.mkIf cfg.enable {
    programs.fish = {
      enable = true;
      generateCompletions = false;
      shellInit = builtins.readFile (configPaths.dev.fish.configDir + "/config.fish");
    };

    xdg.configFile = configPaths.dotfileAdapters.fish { };
  };
}
