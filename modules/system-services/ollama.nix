{
  config,
  lib,
  packageSources,
  ...
}:
let
  cfg = config.my.system.services.ollama;
in
{
  options.my.system.services.ollama.enable = lib.mkEnableOption "Ollama service";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ packageSources.ollama ];

    services.ollama = {
      enable = true;
      package = packageSources.ollama;

      # minuet-ai.nvim uses this local completion model.
      loadModels = [ "qwen2.5-coder:1.5b" ];
    };
  };
}
