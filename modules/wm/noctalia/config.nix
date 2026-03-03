{ config, pkgs, ... }:
let
  configDir = ".config/noctalia";
in {
  home.activation.installNoctaliaConfig = config.lib.dag.entryAfter ["writeBoundary"] ''
    install -D -m 644 ${./config/settings.json} "$HOME/${configDir}/settings.json"
    install -D -m 644 ${./config/plugins.json} "$HOME/${configDir}/plugins.json"
  '';
}
