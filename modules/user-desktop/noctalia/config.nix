{
  configPaths,
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.user.desktop.noctalia;
  configDir = ".config/noctalia";
in
{
  config = lib.mkIf cfg.enable {
    home.activation.installNoctaliaConfig = config.lib.dag.entryAfter [ "writeBoundary" ] ''
      install -D -m 644 ${configPaths.wm.noctaliaConfigDir + "/settings.json"} "$HOME/${configDir}/settings.json"
      install -D -m 644 ${configPaths.wm.noctaliaConfigDir + "/plugins.json"} "$HOME/${configDir}/plugins.json"
      install -D -m 644 ${configPaths.wm.noctaliaConfigDir + "/user-templates.toml"} "$HOME/${configDir}/user-templates.toml"
    '';
  };
}
