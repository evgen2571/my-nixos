{
  config,
  lib,
  ...
}:

let
  cfg = config.my.system.apps.steam;
in
{
  options.my.system.apps.steam.enable = lib.mkEnableOption "Steam";

  config = lib.mkIf cfg.enable {
    programs.gamescope.enable = true;

    programs.steam = {
      enable = true;
      gamescopeSession.enable = true;
    };

    nixpkgs.config.allowUnfreePredicate =
      pkg:
      builtins.elem (lib.getName pkg) [
        "steam"
        "steam-original"
        "steam-unwrapped"
        "steam-run"
      ];
  };
}
