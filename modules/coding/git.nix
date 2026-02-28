{ lib, pkgs, ... }:

{
  programs.ssh = {
    enable = true;
	addKeysToAgent = "yes";
  };

  programs.git = {
    enable = true;

	signing = {
	  key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILIH4JXLBrYVGWWY8Bds34YNR7rGtsggctHVfNibTDjA evgen.10.02.2008.83@gmail.com";
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
