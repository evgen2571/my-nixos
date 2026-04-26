{ ... }:

{
  home.username = "operator";
  home.homeDirectory = "/home/operator";

  my.user.dev.git = {
    userName = "operator";
    userEmail = "150374952+evgen2571@users.noreply.github.com";
    signingKey = "~/.ssh/id_ed25519.pub";
  };

  home.sessionPath = [ "$HOME/.cargo/bin" ];

  home.enableNixpkgsReleaseCheck = false;
  home.stateVersion = "25.11";
}
