{ ... }:
let
  file = ../../secrets/hosts/server.yaml;
in
{
  sops.secrets = {
    vpn-wireguard-private-key = {
      sopsFile = file;
      key = "wireguard_private_key";
      mode = "0400";
      restartUnits = [ "netns-vpn-shared.service" ];
    };
    hide-me-bootstrap-token = {
      sopsFile = file;
      key = "hide_me_bootstrap_token";
      mode = "0400";
      restartUnits = [ "hide-me-vpn.service" ];
    };
  };
}
