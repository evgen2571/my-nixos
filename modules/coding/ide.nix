{ pkgs, ... }:

{
  home.packages = with pkgs; [
    neovim
    clang-tools
    ripgrep
    fzf
    tmux
    kitty
  ];
}
