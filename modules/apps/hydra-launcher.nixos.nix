{
  config,
  lib,
  packageSources,
  pkgs,
  ...
}:

let
  cfg = config.my.system.apps.hydraLauncher;

  # Pin Hydra independently of the system's nixpkgs-unstable revision.
  version = "4.4.0";
  src = pkgs.fetchurl {
    url = "https://github.com/hydralauncher/hydra/releases/download/v${version}/hydralauncher-${version}.AppImage";
    hash = "sha256-Cf20ktAOen/eUyWxqIRaxCJZgScBI6OiAA114l/I87M=";
  };
  appimageContents = pkgs.appimageTools.extract {
    pname = "hydralauncher";
    inherit version src;
  };
in
{
  options.my.system.apps.hydraLauncher.enable = lib.mkEnableOption "Hydra Launcher";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      (pkgs.appimageTools.wrapType2 {
        pname = "hydralauncher";
        inherit version src;

        extraPkgs = p: [ p.python3 ];
        # Hydra's bundled UMU inherits this unless a Proton is selected in its UI.
        profile = ''
          export PROTONPATH=${pkgs.proton-ge-bin.steamcompattool}
        '';

        extraInstallCommands = ''
          install -Dm644 ${appimageContents}/usr/share/icons/hicolor/512x512/apps/hydralauncher.png \
            "$out/share/icons/hicolor/512x512/apps/hydralauncher.png"
          install -Dm644 ${appimageContents}/hydralauncher.desktop \
            "$out/share/applications/hydralauncher.desktop"
          substituteInPlace "$out/share/applications/hydralauncher.desktop" \
            --replace-fail 'Exec=AppRun' "Exec=$out/bin/hydralauncher"

          # Load the bundled UI immediately instead of waiting for the remote page.
          mv "$out/bin/hydralauncher" "$out/bin/.hydralauncher-unwrapped"
          printf '%s\n' \
            '#!${pkgs.runtimeShell}' \
            "exec \"$out/bin/.hydralauncher-unwrapped\" '--host-resolver-rules=MAP release-v${builtins.replaceStrings [ "." ] [ "-" ] version}.hydra-755.pages.dev 127.0.0.1' \"\$@\"" \
            > "$out/bin/hydralauncher"
          chmod +x "$out/bin/hydralauncher"
        '';

        meta = packageSources.hydralauncher.meta // {
          changelog = "https://github.com/hydralauncher/hydra/releases/tag/v${version}";
        };
      })
    ];
  };
}
