{ config, lib, pkgs, ... }:

let
  cfg = config.my.user.dev.terminalWorkflow;
in
{
  options.my.user.dev.terminalWorkflow.enable = lib.mkEnableOption "terminal navigation and CLI search workflow";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      ripgrep
      fd
      fzf
      jq
    ];
  };
}
