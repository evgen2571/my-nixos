{ pkgs, ... }:

{
  home.packages = with pkgs; [
    neovim
    clang
    ripgrep
    fzf
    tmux
    kitty
  ];
}
