{ lib, pkgs, ... }:

{
  programs.git = {
    enable = true;

    # Template: replace these defaults with your own identity.
    userName = lib.mkDefault "Your Name";
    userEmail = lib.mkDefault "you@example.com";
  };

  home.packages = with pkgs; [
    lazygit
  ];
}
