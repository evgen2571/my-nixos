{ config, pkgs, lib, inputs,... }:

let
  cfg = config.my.system.apps.steam;
in
{
  options.my.system.apps.steam.enable = lib.mkEnableOption "Steam";

  config = lib.mkIf cfg.enable (
    {
      nixpkgs.overlays = [ inputs.millennium.overlays.default ];

      programs.gamescope.enable = true;
      programs.steam = {
        enable = true;
      gamescopeSession.enable = true;
        package = pkgs.millennium-steam;
      };

      nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
        "steam"
          "steam-original"
          "steam-unwrapped"
          "steam-run"
      ];
    }
  );
}
