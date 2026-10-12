{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.my.user.dev.neovim;
  providerPython = pkgs.python3.withPackages (
    ps: with ps; [
      pynvim
      jupyter-client
      pillow
      cairosvg
    ]
  );
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
      imagemagick
      gcc
      delve
      lua-language-server
      stylua
      tree-sitter
      matugen
    ];

    home.sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      NVIM_PYTHON_PROVIDER = "${providerPython}/bin/python3";
    };
  };
}
