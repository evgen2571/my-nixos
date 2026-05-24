{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.user.dev.languages.python;
in
{
  options.my.user.dev.languages.python.enable = lib.mkEnableOption "Python development toolchain";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      python3
      uv
      pyright
      ruff
      black
      mypy
      python3Packages.debugpy
    ];
  };
}
