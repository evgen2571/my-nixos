{ ... }:

{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    matchBlocks = {
      "*" = {
        addKeysToAgent = "yes";
      };

      github.com = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/id_ed25519_github";
        identitiesOnly = true;
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
}
