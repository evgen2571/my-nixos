{
  config,
  lib,
  pkgs,
  inputs,
  osConfig ? { },
  ...
}:
let
  cfg = config.my.user.ai.codex;
  agents = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};

  # Preserve the VPN namespace launcher while leaving Codex arguments,
  # MCP settings, and authentication mutable.
  upstreamCommand =
    if cfg.networkNamespace == null then
      lib.getExe cfg.unwrappedPackage
    else
      "${lib.getExe osConfig.my.system.services.networkNamespaces.launcherPackage} codex-${config.home.username}";

  # ChatGPT authentication remains mutable; only the transport defaults
  # to HTTP Responses when Codex uses the shared VPN namespace.
  httpOnlyArgs = lib.optionals cfg.httpOnly [
    "-c"
    ''model_provider="openai_http"''
    "-c"
    ''model_providers.openai_http={name="openai",base_url="https://chatgpt.com/backend-api/codex",wire_api="responses",requires_openai_auth=true,supports_websockets=false}''
  ];
  wrapped = pkgs.writeShellScriptBin "codex" ''
    exec ${upstreamCommand} ${lib.escapeShellArgs httpOnlyArgs} "$@"
  '';
in
{
  options.my.user.ai.codex = {
    enable = lib.mkEnableOption "Codex CLI";
    networkNamespace = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "vpn";
      description = "Route Codex and all child processes through this system-managed VPN namespace; null uses normal host networking.";
    };
    httpOnly = lib.mkOption {
      type = lib.types.bool;
      default = cfg.networkNamespace != null;
      description = "Prefer the ChatGPT HTTP Responses transport instead of WebSockets, by default for VPN-isolated Codex. Set false to restore upstream transport selection.";
    };
    unwrappedPackage = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      default = agents.codex;
      description = "Original Codex package from the pinned llm-agents input.";
    };
    package = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      default = wrapped;
      description = "Installed Codex executable with namespace routing.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = lib.optional (cfg.networkNamespace != null) {
      assertion =
        (osConfig.my.system.services.networkNamespaces.enable or false)
        && (osConfig.my.system.services.networkNamespaces.namespaces.${cfg.networkNamespace}.enable or false);
      message = "Codex networkNamespace requires the corresponding system VPN namespace to be enabled.";
    };
    home.packages = [ cfg.package ];
  };
}
