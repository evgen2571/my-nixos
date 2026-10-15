{ config, ... }:

let
  user = config.my.primaryUser.name;
  file = ../../secrets/hosts/pc.yaml;
in
{
  sops.secrets = {
    vpn-wireguard-private-key = {
      sopsFile = ../../secrets/vpn/pc.yaml;
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

    ssh-gitlab-private-key = {
      sopsFile = file;
      key = "ssh_gitlab_private_key";

      owner = user;
      mode = "0400";

      path = "/home/${user}/.ssh/id_ed25519_gitlab";
    };

    ssh-pc-private-key = {
      sopsFile = file;
      key = "ssh_pc_private_key";

      owner = user;
      mode = "0400";

      path = "/home/${user}/.ssh/id_ed25519_nixos_pc";
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
