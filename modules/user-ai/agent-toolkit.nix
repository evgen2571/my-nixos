{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.my.user.ai.agentToolkit;
in
{
  # This is a non-flake input: use its pinned Nix module without replacing
  # existing Codex login, mutable settings or application configuration.
  imports = [ (builtins.toPath "${inputs.agent-toolkit}/nix/home-manager.nix") ];

  options.my.user.ai.agentToolkit.enable =
    lib.mkEnableOption "declarative, pinned Codex skills and Serena MCP";

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.my.user.ai.codex.enable;
        message = "Agent toolkit requires my.user.ai.codex.enable.";
      }
    ];

    programs.agent-toolkit = {
      enable = true;
      # Existing account-managed Superpowers cannot yet be disabled safely.
      # Suppress standalone duplicates until its account-level migration.
      existingPlugins = [ "superpowers" ];
      profiles = [ ];
      skills = [ ];
      installCatalog = false;
      serenaPackage = inputs.serena.packages.${pkgs.stdenv.hostPlatform.system}.serena;
      ponytail = {
        enable = true;
        mode = "lite";
      };
    };
  };
}
