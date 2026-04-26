{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.my.user.dev.neovim;
in
{
  imports = [
    ./config.nix
  ];

  options.my.user.dev.neovim.enable = lib.mkEnableOption "Neovim";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      neovim

      matugen
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
  };
}
