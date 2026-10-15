{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.my.user.dev.neovim;
  neovimWithPython = pkgs.neovim.override {
    withPython3 = true;
    extraPython3Packages = ps: with ps; [
      jupyter-client
      pillow
      cairosvg
      nbformat
    ];
  };
in
{
  imports = [
    ./config.nix
  ];

  options.my.user.dev.neovim.enable = lib.mkEnableOption "Neovim";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      neovimWithPython
      git
      curl
      unzip
      gzip
      xz
      wl-clipboard
      xclip
      nodejs
      imagemagick
      gcc
      delve
      lua-language-server
      stylua
      marksman
      prettier
      tree-sitter
      matugen
    ];

    home.sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };
  };
}
