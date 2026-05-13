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
      git
      curl
      unzip
      gzip
      xz
      wl-clipboard
      xclip
      nodejs
      python313Packages.pynvim
      python313Packages.jupyter-client
      lua-language-server
      stylua
      tree-sitter
      matugen
    ];

    home.sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };
  };
}
