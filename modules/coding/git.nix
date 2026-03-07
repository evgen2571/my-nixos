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
	  key = "~/.ssh/id_ed25519";
	  signByDefault = true;
	};

    settings = {
	  user = {
	    name = "evgen2571";
	    email = "evgen.10.02.2008.83@gmail.com";
	  };
	  gpg = {
	    format = "ssh";
	  };
	  init.defaultBranch = "main";
	};

  };

  home.packages = with pkgs; [
    lazygit
  ];
}
