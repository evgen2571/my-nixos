{
  config,
  lib,
  ...
}:

let
  cfg = config.my.system.dev.fish;
in
{
  options.my.system.dev.fish.enable = lib.mkEnableOption "Fish shell system integration";

  config = lib.mkIf cfg.enable {
    programs.fish.enable = true;
  };
}
