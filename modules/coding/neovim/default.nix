{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./config.nix
  ];

  home.packages = with pkgs; [
    neovim

    git
    curl
    unzip
    gzip
    xz

    ripgrep
    fd
    gnutar
    gcc
    gnumake
    pkg-config
    luarocks

    wl-clipboard
    xclip

    nodejs
    python3
    lua-language-server
    stylua
    tree-sitter

    jq
    fzf
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };
}
