{ ... }:
{
  sops.secrets = {
    vpn-wireguard-private-key = {
      sopsFile = ../../secrets/vpn/server.yaml;
      key = "wireguard_private_key";
      mode = "0400";
      restartUnits = [ "netns-vpn-shared.service" ];
    };
    hide-me-bootstrap-token = {
      sopsFile = ../../secrets/vpn/server.yaml;
      key = "hide_me_bootstrap_token";
      mode = "0400";
      restartUnits = [ "hide-me-vpn.service" ];
    };
  };
}
