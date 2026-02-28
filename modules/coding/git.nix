{ lib, pkgs, ... }:

{
  programs.ssh = {
    enable = true;
	addKeysToAgent = "yes";
  };

  programs.git = {
    enable = true;

	signing = {
	  key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA example";
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
