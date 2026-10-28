{
  config,
  lib,
  pkgs,
  packageSources,
  osConfig ? { },
  ...
}:

let
  cfg = config.my.user.ai.antigravityCli;
in
{
  options.my.user.ai.antigravityCli = {
    enable = lib.mkEnableOption "Antigravity CLI";

    networkNamespace = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "vpn";
      description = "Route Antigravity and its child processes through this system-managed VPN namespace.";
    };

    unwrappedPackage = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      default = packageSources.antigravity-cli;
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = lib.optional (cfg.networkNamespace != null) {
      assertion =
        (osConfig.my.system.services.networkNamespaces.enable or false)
        && (osConfig.my.system.services.networkNamespaces.namespaces.${cfg.networkNamespace}.enable or false
        );
      message = "Antigravity networkNamespace requires the corresponding system VPN namespace to be enabled.";
    };

    home.packages = [
      (
        if cfg.networkNamespace == null then
          cfg.unwrappedPackage
        else
          pkgs.writeShellScriptBin "agy" ''
            exec ${lib.getExe osConfig.my.system.services.networkNamespaces.launcherPackage} antigravity-cli-${config.home.username} "$@"
          ''
      )
    ];
  };
}
