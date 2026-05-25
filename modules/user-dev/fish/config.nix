{
  config,
  lib,
  ...
}:

let
  cfg = config.my.user.dev.fish;
in
{
  config = lib.mkIf cfg.enable {
    xdg.configFile."fish".source = cfg.configDir;
  };
}
