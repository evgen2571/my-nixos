{
  config,
  ...
}:

{
  services.ollama = {
    enable = true;

    # preload models, see https://ollama.com/library
    loadModels = [
      "qwen2.5-coder:1.5b"
    ];
  };
}
