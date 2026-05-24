{ config, lib,  inputs, pkgs, ... }:

let
  cfg = config.my.system.services.ollama;
in
{
  options.my.system.services.ollama.enable = lib.mkEnableOption "Ollama service";

  config = lib.mkIf cfg.enable (
    let
      unstable = import inputs.nixpkgs-unstable {
        system = pkgs.system;
        config.allowUnfree = true;
      };
    in
    {
      environment.systemPackages = [ unstable.ollama ];

      services.ollama = {
        enable = true;
        package = unstable.ollama;

        # Preload local code-completion model for minuet-ai.nvim.
        loadModels = [
          "qwen2.5-coder:1.5b"
        ];
      };
    }
  );
}
