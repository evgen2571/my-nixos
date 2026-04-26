{ config, pkgs, inputs, lib, ... }:

let
  cfg = config.my.user.apps.zenBrowser;
in
{
  imports = [
    # Options:
    # inputs.zen-browser.homeModules.beta
    # inputs.zen-browser.homeModules.twilight
    # inputs.zen-browser.homeModules.twilight-official
    inputs.zen-browser.homeModules.twilight
  ];

  options.my.user.apps.zenBrowser.enable = lib.mkEnableOption "Zen Browser";

  config = lib.mkIf cfg.enable {
    programs.zen-browser.enable = true;
  };
}
