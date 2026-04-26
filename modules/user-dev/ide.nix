{ config, lib,  pkgs, ... }:

let
  cfg = config.my.user.dev.ide;
in
{
  options.my.user.dev.ide.enable = lib.mkEnableOption "IDE support tools";

  config = lib.mkIf cfg.enable (
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
        matugen

        python313Packages.pynvim
        python313Packages.jupyter-client
      ];
    }
  );
}
