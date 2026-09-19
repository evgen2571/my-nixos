{ config, ... }:

let
  user = config.my.primaryUser.name;
  file = ../../secrets/hosts/laptop.yaml;
in
{
  sops.secrets = {
    user-password = {
      sopsFile = file;
      key = "user_password_hash";
      neededForUser = true;
    };
  };

  users.mutableUsers = false;

  users.users.${user}.hashedPasswordFile = config.sops.secrets.user-password.path;
}
