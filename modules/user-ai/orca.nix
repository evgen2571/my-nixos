{
  config,
  lib,
  pkgs,
  packageSources,
  osConfig ? { },
  ...
}:

let
  cfg = config.my.user.ai.orca;
in
{
  options.my.user.ai.orca = {
    enable = lib.mkEnableOption "Orca agent workspace";

    unwrappedPackage = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      default = packageSources.orca;
    };

    networkNamespace = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      packageSources.orca
    ]
    ++ lib.optional (cfg.networkNamespace != null) (
      pkgs.writeShellScriptBin "orca-vpn" ''
        exec ${lib.getExe osConfig.my.system.services.networkNamespaces.launcherPackage} orca-${config.home.username} "$@"
      ''
    );
  };
}
