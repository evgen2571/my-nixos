{
  config,
  packageSources,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.user.dev.languages.godot;
in
{
  options.my.user.dev.languages.godot.enable = lib.mkEnableOption "Godot game development";

  config = lib.mkIf cfg.enable {
    home.packages = [
      packageSources.godot_4
      pkgs.gdtoolkit_4
    ];
  };
}
