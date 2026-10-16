{ config, ... }:

let
  user = config.my.primaryUser.name;
  file = ../../secrets/hosts/laptop.yaml;
in
{
  sops.secrets = {
    vpn-wireguard-private-key = {
      sopsFile = file;
      key = "wireguard_private_key";
      mode = "0400";
      restartUnits = [ "netns-vpn-shared.service" ];
    };
    ssh-github-private-key = {
      sopsFile = file;
      key = "ssh_github_private_key";

      owner = user;
      mode = "0400";

      path = "/home/${user}/.ssh/id_ed25519_github";
    };

    ssh-laptop-private-key = {
      sopsFile = file;
      key = "ssh_laptop_private_key";

      owner = user;
      mode = "0400";

      path = "/home/${user}/.ssh/id_ed25519_nixos_lp";
    };

    user-password = {
      sopsFile = file;
      key = "user_password_hash";
      neededForUsers = true;
    };

    openrouter-api-key = {
      sopsFile = file;
      key = "openrouter_api_key";
      owner = user;
      mode = "0400";
    };
  };

  users.mutableUsers = false;

  users.users.${user}.hashedPasswordFile = config.sops.secrets.user-password.path;
}
