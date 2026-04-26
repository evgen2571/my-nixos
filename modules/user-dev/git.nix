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
        name = "evgen2571";
        email = "evgen.10.02.2008.83@gmail.com";
      };
      init.defaultBranch = "main";
    };

  };

  home.packages = with pkgs; [
    lazygit
  ];
}
