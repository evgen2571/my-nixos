{
  config,
  configPaths,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.my.user.desktop.noctalia;
  noctaliaPackage = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
  noctaliaShellPackage = pkgs.symlinkJoin {
    name = "noctalia-shell-${noctaliaPackage.version or "unstable"}";
    paths = [ noctaliaPackage ];
    postBuild = ''
      if [ -e "$out/bin/noctalia" ] && [ ! -e "$out/bin/noctalia-shell" ]; then
        ln -s noctalia "$out/bin/noctalia-shell"
      fi
    '';
    meta = (noctaliaPackage.meta or { }) // {
      mainProgram = "noctalia-shell";
    };
  };
in
{
  imports = [
    inputs.noctalia.homeModules.default
    (lib.mkAliasOptionModule [ "programs" "noctalia-shell" ] [ "programs" "noctalia" ])
    ./config.nix
  ];

  options.my.user.desktop.noctalia = {
    enable = lib.mkEnableOption "Noctalia shell";

    configFile = lib.mkOption {
      type = lib.types.path;
      default = configPaths.wm.noctaliaConfigDir + "/config.toml";
      description = "Noctalia v5 TOML config to install as ~/.config/noctalia/config.toml.";
    };

    profile = lib.mkOption {
      type = lib.types.enum [
        "laptop"
        "pc"
      ];
      description = "Host-specific Noctalia bar and widget configuration.";
    };

    legacyConfig.enable = lib.mkEnableOption "legacy Noctalia v4 JSON/plugins/template config installation";
    legacyConfig.settings = lib.mkOption {
      type = (pkgs.formats.json { }).type;
      default = { };
      description = "Narrow overrides for the optional legacy Noctalia v4 JSON settings.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.activation.pruneStaleNoctaliaSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ${pkgs.python3}/bin/python3 ${configPaths.wm.noctaliaConfigDir}/prune-stale-settings.py \
        "$HOME/.local/state/noctalia/settings.toml"
    '';

    programs.noctalia = {
      enable = true;
      package = noctaliaShellPackage;
      systemd.enable = true;
    };
  };
}
