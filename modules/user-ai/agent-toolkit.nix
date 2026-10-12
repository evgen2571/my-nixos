{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  # This module is discovered only for desktop Home Manager profiles.
  imports = [ (inputs.agent-toolkit + "/nix/home-manager.nix") ];

  config = lib.mkIf config.my.user.ai.codex.enable {
    programs.agent-toolkit = {
      enable = true;

      # The account-managed Superpowers plugin is still enabled. Avoid
      # duplicate standalone skills until it can be disabled safely.
      existingPlugins = [ "superpowers" ];
      profiles = [ ];
      skills = [ ];
      installCatalog = false;

      serenaPackage = inputs.serena.packages.${pkgs.stdenv.hostPlatform.system}.default;

      # Preparation is declarative; installation and hook trust are not.
      ponytail.enable = true;
      ponytail.mode = "disabled";
    };
  };
}
