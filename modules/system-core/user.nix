{ config, lib, pkgs, ... }:

let
  cfg = config.my.primaryUser;
in
{
  options.my.primaryUser = {
    enable = lib.mkEnableOption "the host primary user adapter";

    name = lib.mkOption {
      type = lib.types.str;
      description = "Primary user account name.";
    };

    description = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Human-readable primary user description.";
    };

    extraGroups = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Supplementary groups for the primary user.";
    };

    shell = lib.mkOption {
      type = lib.types.package;
      default = pkgs.bash;
      description = "Login shell package for the primary user.";
    };

    authorizedKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "SSH public keys authorized for the primary user.";
    };

    home = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to wire a matching Home Manager user for the primary user.";
      };

      module = lib.mkOption {
        type = lib.types.path;
        default = ../../home/evgen2571/home.nix;
        description = "Base Home Manager module for the selected primary user.";
      };

      settings = lib.mkOption {
        type = lib.types.attrs;
        default = { };
        description = "Host-specific Home Manager settings for the primary user.";
      };
    };

    git = {
      userName = lib.mkOption {
        type = lib.types.str;
        default = cfg.name;
        defaultText = lib.literalExpression "config.my.primaryUser.name";
        description = "Git author name for the primary user's Home Manager profile.";
      };

      userEmail = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Git author email for the primary user's Home Manager profile.";
      };

      signingKey = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Git signing key for the primary user's Home Manager profile.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.${cfg.name} = {
      isNormalUser = true;
      inherit (cfg) description extraGroups shell;
      openssh.authorizedKeys.keys = cfg.authorizedKeys;
    };

    home-manager.users.${cfg.name} = lib.mkIf cfg.home.enable (lib.mkMerge [
      {
        imports = [ cfg.home.module ];

        home.username = cfg.name;
        home.homeDirectory = "/home/${cfg.name}";

        my.user.dev.git = lib.mkMerge [
          {
            userName = cfg.git.userName;
            userEmail = cfg.git.userEmail;
          }
          (lib.mkIf (cfg.git.signingKey != null) {
            signingKey = cfg.git.signingKey;
          })
        ];
      }
      cfg.home.settings
    ]);
  };
}
