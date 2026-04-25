{
  configPaths,
  config,
  pkgs,
  ...
}:
let
  configDir = ".config/noctalia";
in {
  home.activation.installNoctaliaConfig = config.lib.dag.entryAfter ["writeBoundary"] ''
    install -D -m 644 ${configPaths.wm.noctaliaConfigDir + "/settings.json"} "$HOME/${configDir}/settings.json"
    install -D -m 644 ${configPaths.wm.noctaliaConfigDir + "/plugins.json"} "$HOME/${configDir}/plugins.json"
    install -D -m 644 ${configPaths.wm.noctaliaConfigDir + "/user-templates.toml"} "$HOME/${configDir}/user-templates.toml"
  '';
}
