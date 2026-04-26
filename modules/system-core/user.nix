{ config, lib, pkgs, ... }:

let
  cfg = config.my.system.user;
in
{
  options.my.system.user = {
    enable = lib.mkEnableOption "a primary normal user account";

    name = lib.mkOption {
      type = lib.types.str;
      description = "User account name.";
    };

    description = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Human-readable user description.";
    };

    extraGroups = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Supplementary groups for the user.";
    };

    shell = lib.mkOption {
      type = lib.types.package;
      default = pkgs.bash;
      description = "Login shell package for the user.";
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.${cfg.name} = {
      isNormalUser = true;
      inherit (cfg) description extraGroups shell;
    };
  };
}
