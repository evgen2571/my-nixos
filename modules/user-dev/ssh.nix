{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:

let
  cfg = config.my.user.dev.ssh;

  agentIdentity =
    if osConfig.networking.hostName == "nixos-pc" then
      "~/.ssh/id_ed25519_nixos_pc"
    else if osConfig.networking.hostName == "nixos-lp" then
      "~/.ssh/id_ed25519_nixos_lp"
    else
      null;
in
{
  options.my.user.dev.ssh = {
    serverHost = lib.mkOption {
      type = lib.types.str;
      default = "nixos-server";
      description = ''
        Tailscale MagicDNS hostname used for the home server.
      '';
    };

    serverIdentityFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Private key used to authenticate to the home server.
        Set this per client host so `ssh server` always selects the correct key.
      '';
    };
  };

  config = {
    home.packages = [
      pkgs.sshfs
    ];

    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;

      settings = {
        "*" = {
          AddKeysToAgent = "yes";
          ServerAliveInterval = 30;
          ServerAliveCountMax = 3;
        };

        "github.com" = {
          HostName = "github.com";
          User = "git";
          IdentityFile = "~/.ssh/id_ed25519_github";
          IdentitiesOnly = true;
        };

        "agent" = {
          HostName = "100.126.39.112";
          User = "agent";
          IdentityFile = agentIdentity;
          IdentitiesOnly = true;
        };

        "server" = {
          HostName = cfg.serverHost;
          User = "server";
          IdentitiesOnly = true;
        }
        // lib.optionalAttrs (cfg.serverIdentityFile != null) {
          IdentityFile = cfg.serverIdentityFile;
        };
      };
    };
  };
}
