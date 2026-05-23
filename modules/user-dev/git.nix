{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.user.dev.git;
in
{
  options.my.user.dev.git = {
    enable = lib.mkEnableOption "Git and SSH user configuration";

    userName = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Git user.name value. Leave null to avoid setting a personal identity in the shared module.";
    };

    userEmail = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Git user.email value. Leave null to avoid setting a personal identity in the shared module.";
    };

    signingKey = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "SSH or GPG signing key for Git commits. Leave null to disable signing configuration.";
    };

    signByDefault = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether Git should sign commits by default when signingKey is set.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;

      matchBlocks = {
        "*" = {
          addKeysToAgent = "yes";
        };

        "hermes-space" = {
          hostname = "100.89.6.98";
          user = "agent";
          identityFile = "~/.ssh/hermes_server";
          identitiesOnly = true;
        };

        "server-lp" = {
          hostname = "100.89.6.98";
          user = "server";
          identityFile = "~/.ssh/hermes_server";
          identitiesOnly = true;
        };
      };
    };

    programs.git = {
      enable = true;

      settings = {
        init.defaultBranch = "main";
      }
      // lib.optionalAttrs (cfg.userName != null || cfg.userEmail != null) {
        user =
          lib.optionalAttrs (cfg.userName != null) {
            name = cfg.userName;
          }
          // lib.optionalAttrs (cfg.userEmail != null) {
            email = cfg.userEmail;
          };
      };
    }
    // lib.optionalAttrs (cfg.signingKey != null) {
      signing = {
        key = cfg.signingKey;
        signByDefault = cfg.signByDefault;
        format = "ssh";
      };
    };

    home.packages = with pkgs; [
      lazygit
    ];
  };
}
