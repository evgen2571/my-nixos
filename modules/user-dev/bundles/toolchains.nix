{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.user.dev.toolchains;
in
{
  options.my.user.dev.toolchains.enable = lib.mkEnableOption "generic developer tooling";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      zip
      nil
      nix
      nixd
      luarocks
      direnv
      nix-direnv
    ];

    # Let projects opt into per-repo toolchains with a checked-in `.envrc`
    # containing `use flake` or `use nix`, without manually entering nix-shell.
    xdg.configFile."direnv/direnvrc".text = ''
      source ${pkgs.nix-direnv}/share/nix-direnv/direnvrc
    '';
  };
}
