{ config, pkgs, ... }:

let
  unstable = import <nixos-unstable> {
    config = {
      allowUnfree = true;
    };
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
