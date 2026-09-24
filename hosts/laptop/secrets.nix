{ config, ... }:

let
  user = config.my.primaryUser.name;
  file = ../../secrets/hosts/laptop.yaml;
in
{
  sops.secrets = {
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
  };

  users.mutableUsers = false;

  users.users.${user}.hashedPasswordFile = config.sops.secrets.user-password.path;
}
