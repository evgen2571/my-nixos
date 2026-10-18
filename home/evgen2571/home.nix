{
  lib,
  ...
}:

{
  home.sessionPath = [ "$HOME/.cargo/bin" ];

  home.enableNixpkgsReleaseCheck = false;
  home.stateVersion = lib.mkDefault "25.11";
}
