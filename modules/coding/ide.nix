{ pkgs, ... }:

{
  home.packages = with pkgs; [
   neovim
   cargo
   zip
   unzip
   curl
   ripgrep
   kitty
   tmux
   fzf
   cmake
   gnumake
   gcc
   python3
   uv
   go
  ];
}
