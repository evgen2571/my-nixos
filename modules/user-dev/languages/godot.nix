{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.user.dev.languages.godot;
  unstable = import inputs.nixpkgs-unstable {
    system = pkgs.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };
in
{
  options.my.user.dev.languages.godot.enable = lib.mkEnableOption "Godot game development";

  config = lib.mkIf cfg.enable {
    home.packages = [
      unstable.godot_4
      pkgs.gdtoolkit_4
    ];
  };
}
