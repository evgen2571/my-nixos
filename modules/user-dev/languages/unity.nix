{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.user.dev.languages.unity;
  unstable = import inputs.nixpkgs-unstable {
    system = pkgs.system;
    config.allowUnfree = true;
  };
in
{
  options.my.user.dev.languages.unity.enable = lib.mkEnableOption "Unity game development";

  config = lib.mkIf cfg.enable {
    home.packages = [
      unstable.unityhub
      # Supplies the OmniSharp executable used by Neovim's C# LSP client.
      pkgs.omnisharp-roslyn
    ];
  };
}
