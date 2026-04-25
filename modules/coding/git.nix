{ lib, pkgs, ... }:

{
  programs.ssh = {
    enable = true;
    matchBlocks."*".addKeysToAgent = "yes";
    enableDefaultConfig = false;
  };

  programs.git = {
    enable = true;

    signing = {
      key = "~/.ssh/id_ed25519.pub";
      signByDefault = true;
      format = "ssh";
    };

    settings = {
      user = {
        name = "operator";
        email = "150374952+evgen2571@users.noreply.github.com";
      };
      init.defaultBranch = "main";
    };

  };

  home.packages = with pkgs; [
    lazygit
  ];
}
