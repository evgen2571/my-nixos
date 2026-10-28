{
  config,
  lib,
  pkgs,
  packageSources,
  osConfig ? { },
  ...
}:

let
  cfg = config.my.user.ai.chatgpt;
in
{
  options.my.user.ai.chatgpt = {
    enable = lib.mkEnableOption "ChatGPT desktop app";

    networkNamespace = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "vpn";
      description = "Route ChatGPT and its child processes through this system-managed VPN namespace.";
    };

    unwrappedPackage = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      default = packageSources.chatgpt;
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = lib.optional (cfg.networkNamespace != null) {
      assertion =
        (osConfig.my.system.services.networkNamespaces.enable or false)
        && (osConfig.my.system.services.networkNamespaces.namespaces.${cfg.networkNamespace}.enable or false
        );
      message = "ChatGPT networkNamespace requires the corresponding system VPN namespace to be enabled.";
    };

    home.packages = [
      (
        if cfg.networkNamespace == null then
          cfg.unwrappedPackage
        else
          pkgs.symlinkJoin {
            name = "chatgpt-vpn";
            paths = [ cfg.unwrappedPackage ];
            nativeBuildInputs = [ pkgs.makeWrapper ];
            postBuild = ''
              rm "$out/bin/chatgpt" "$out/share"
              makeWrapper ${lib.getExe osConfig.my.system.services.networkNamespaces.launcherPackage} \
                "$out/bin/chatgpt" --add-flags chatgpt-${config.home.username}
              # Desktop and URL-handler launches must use the same VPN wrapper.
              mkdir -p "$out/share/applications"
              ln -s ${cfg.unwrappedPackage}/share/pixmaps "$out/share/pixmaps"
              substitute ${cfg.unwrappedPackage}/share/applications/chatgpt.desktop \
                "$out/share/applications/chatgpt.desktop" \
                --replace-fail "Exec=chatgpt" "Exec=$out/bin/chatgpt"
            '';
          }
      )
    ];
  };
}
