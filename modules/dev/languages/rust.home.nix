{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.user.dev.languages.rust;
in
{
  options.my.user.dev.languages.rust.enable = lib.mkEnableOption "Rust development toolchain";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      lldb
      rustc
      cargo
      rustfmt
      clippy
      rust-analyzer
      cargo-edit
      cargo-expand
      cargo-nextest
      cargo-watch
      bacon
    ];
  };
}
