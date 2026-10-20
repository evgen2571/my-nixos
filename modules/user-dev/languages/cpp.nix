{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.user.dev.languages.cpp;
in
{
  options.my.user.dev.languages.cpp.enable = lib.mkEnableOption "C and C++ development toolchain";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      gcc
      clang-tools
      cmake
      gnumake
      pkg-config
      gdb
      lldb
    ];
  };
}
