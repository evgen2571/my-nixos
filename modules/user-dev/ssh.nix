{ pkgs, ... }:

{
  home.packages = [
    pkgs.sshfs
  ];

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    matchBlocks = {
      "*" = {
        addKeysToAgent = "yes";
      };

      "github.com" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/id_ed25519_github";
        identitiesOnly = true;
      };

      "agent" = {
        hostname = "192.0.2.13";
        user = "agent";
        identityFile = "~/.ssh/hermes_host";
        identitiesOnly = true;
      };

      "server-lp" = {
        hostname = "192.0.2.14";
        user = "server";
        identityFile = "~/.ssh/hermes_server";
        identitiesOnly = true;
      };
    };
  };
}
