{ pkgs, ... }:

{
  home.packages = with pkgs; [
    neovim
    clang-tools
    ripgrep
    fzf
    tmux
	tmux-sessionizer
    kitty
	readline.dev
	lua5_1
	imagemagick

	python313Packages.pynvim
	python313Packages.jupyter-client
  ];
}
