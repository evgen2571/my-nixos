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
      just
      zip
      nil
      nix
      nixd
      nixfmt
      statix
      deadnix
      stylua
      shellcheck
      shfmt
      luarocks
      direnv
      nix-direnv
      nh
      nix-tree
      bat
      eza
      tealdeer
    ];

    programs.atuin = {
      enable = true;
      enableFishIntegration = false; # Fish is configured through config/fish/config.fish.
      settings.auto_sync = false;
    };

    # Let projects opt into per-repo toolchains with a checked-in `.envrc`
    # containing `use flake` or `use nix`, without manually entering nix-shell.
    xdg.configFile."direnv/direnvrc".text = ''
      source ${pkgs.nix-direnv}/share/nix-direnv/direnvrc
    '';
  };
}
