{ inputs, pkgs, ... }:

let
  unstable = import inputs.nixpkgs-unstable {
    system = pkgs.system;
    config.allowUnfree = true;
  };
in
{
  services.ollama = {
    enable = true;
    package = unstable.ollama;

    # preload models, see https://ollama.com/library
    loadModels = [
      "qwen2.5-coder:1.5b"
      "gemma4:e4b"
    ];
  };
}
