{
  config,
  lib,
  ...
}:
let
  cfg = config.my.user.dev.zoxide;
in
{
  options.my.user.dev.zoxide.enable = lib.mkEnableOption "Zoxide: smart cd";

  config = lib.mkIf cfg.enable {
    programs.zoxide = {
      enable = true;
      enableFishIntegration = true;
      options = [ "--cmd cd" ];
    };
  };
}
