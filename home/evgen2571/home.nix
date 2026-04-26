{ ... }:

{
  home.username = "evgen2571";
  home.homeDirectory = "/home/evgen2571";

  my.user.dev.git = {
    userName = "evgen2571";
    userEmail = "evgen.10.02.2008.83@gmail.com";
    signingKey = "~/.ssh/id_ed25519.pub";
  };

  home.sessionPath = [ "$HOME/.cargo/bin" ];

  home.enableNixpkgsReleaseCheck = false;
  home.stateVersion = "25.11";
}
