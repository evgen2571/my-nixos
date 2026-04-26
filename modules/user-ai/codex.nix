{ config, lib,  pkgs, ... }:

let
  cfg = config.my.user.ai.codex;
in
{
  options.my.user.ai.codex.enable = lib.mkEnableOption "Codex CLI";

  config = lib.mkIf cfg.enable (
    {
      home.packages = with pkgs; [
        codex
      ];
    }
  );
}
