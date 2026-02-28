{ lib, pkgs, ... }:

{
  programs.ssh = {
    enable = true;
	addKeysToAgent = "yes";           
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
	    name = "operator";
	    email = "150374952+evgen2571@users.noreply.github.com";
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
