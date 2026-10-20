{ config, lib, ... }:

let
  cfg = config.my.user.dev.workstation;
in
{
  options.my.user.dev.workstation.enable = lib.mkEnableOption "developer workstation baseline";

  config = lib.mkIf cfg.enable {
    my.user.dev = {
      fish.enable = lib.mkDefault true;
      git.enable = lib.mkDefault true;
      github.enable = lib.mkDefault true;
      kitty.enable = lib.mkDefault true;
      neovim.enable = lib.mkDefault true;
      starship.enable = lib.mkDefault true;
      terminalWorkflow.enable = lib.mkDefault true;
      tmux.enable = lib.mkDefault true;
      toolchains.enable = lib.mkDefault true;
      zoxide.enable = lib.mkDefault true;
    };
  };
}
