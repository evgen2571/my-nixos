{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.user.ai.llamaCpp;
in
{
  options.my.user.ai.llamaCpp.enable = lib.mkEnableOption "llama.cpp";

  config = lib.mkIf cfg.enable ({
    home.packages = with pkgs; [
      llama-cpp
    ];
  });
}
