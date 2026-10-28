{
  config,
  lib,
  pkgs,
  packageSources,
  osConfig ? { },
  ...
}:

let
  cfg = config.my.user.ai.claudeCode;
in
{
  options.my.user.ai.claudeCode = {
    enable = lib.mkEnableOption "Claude Code";

    networkNamespace = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "vpn";
      description = "Route Claude Code and its child processes through this system-managed VPN namespace.";
    };

    unwrappedPackage = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      default = packageSources.claude-code;
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = lib.optional (cfg.networkNamespace != null) {
      assertion =
        (osConfig.my.system.services.networkNamespaces.enable or false)
        && (osConfig.my.system.services.networkNamespaces.namespaces.${cfg.networkNamespace}.enable or false
        );
      message = "Claude Code networkNamespace requires the corresponding system VPN namespace to be enabled.";
    };

    home.packages = [
      (
        if cfg.networkNamespace == null then
          cfg.unwrappedPackage
        else
          pkgs.writeShellScriptBin "claude" ''
            exec ${lib.getExe osConfig.my.system.services.networkNamespaces.launcherPackage} claude-code-${config.home.username} "$@"
          ''
      )
    ];
  };
}
