{
  config,
  packageSources,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.user.dev.languages.unity;
in
{
  options.my.user.dev.languages.unity.enable = lib.mkEnableOption "Unity game development";

  config = lib.mkIf cfg.enable {
    home.packages = [
      packageSources.unityhub
      # Supplies the OmniSharp executable used by Neovim's C# LSP client.
      pkgs.omnisharp-roslyn
      # OmniSharp uses the SDK to load Unity-generated C# projects.
      pkgs.dotnet-sdk
    ];
  };
}
