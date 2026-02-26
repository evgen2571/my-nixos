{ config, pkgs, inputs, lib, ... }:

{
  imports = [
    # Options:
    # inputs.zen-browser.homeModules.beta
    # inputs.zen-browser.homeModules.twilight
    # inputs.zen-browser.homeModules.twilight-official
    inputs.zen-browser.homeModules.twilight
  ];

  # Enable the browser
  programs.zen-browser.enable = true;

  programs.zen-browser.suppressXdgMigrationWarning = true;
  # programs.zen-browser.policies = { DisableAppUpdate = true; };
}
