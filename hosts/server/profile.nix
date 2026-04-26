{ modulePaths, ... }:

{
  imports = [
    modulePaths.systemServices.vpnbookWireguardFailover
  ];

  services.hermes-agent = {
    enable = true;
    addToSystemPackages = true;
    environmentFiles = [ "/var/lib/hermes/env" ];

    settings = {
      model.default = "openai/gpt-5.4";
      toolsets = [ "all" ];
      terminal = {
        backend = "local";
        timeout = 180;
      };
    };
  };

  my.system.services.vpnbookWireguardFailover = {
    enable = true;
    configDir = "/etc/wireguard/vpnbook";
    stateDir = "/var/lib/vpnbook-wireguard";
    interfaceName = "vpnbook0";
    checkInterval = "1min";
  };
}
