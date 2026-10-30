{
  config,
  lib,
  pkgs,
  osConfig ? { },
  ...
}:

let
  cfg = config.my.user.apps.ciscoPacketTracer;
in
{
  options.my.user.apps.ciscoPacketTracer = {
    enable = lib.mkEnableOption "Cisco Packet Tracer";

    networkNamespace = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "vpn";
      description = "Route Packet Tracer and its child processes through this system-managed VPN namespace.";
    };

    unwrappedPackage = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      default = pkgs.cisco-packet-tracer_9;
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = lib.optional (cfg.networkNamespace != null) {
      assertion =
        (osConfig.my.system.services.networkNamespaces.enable or false)
        && (osConfig.my.system.services.networkNamespaces.namespaces.${cfg.networkNamespace}.enable or false
        );
      message = "Packet Tracer networkNamespace requires the corresponding system VPN namespace to be enabled.";
    };

    home.packages = [
      (
        if cfg.networkNamespace == null then
          cfg.unwrappedPackage
        else
          pkgs.symlinkJoin {
            name = "cisco-packet-tracer-vpn";
            paths = [ cfg.unwrappedPackage ];
            nativeBuildInputs = [ pkgs.makeWrapper ];
            postBuild = ''
              rm "$out/bin/packettracer9"
              makeWrapper ${lib.getExe osConfig.my.system.services.networkNamespaces.launcherPackage} \
                "$out/bin/packettracer9" --add-flags cisco-packet-tracer-${config.home.username}
              # Both desktop entries must use the VPN wrapper, including file opens.
              for desktop in ${cfg.unwrappedPackage}/share/applications/*.desktop; do
                target="$out/share/applications/$(basename "$desktop")"
                rm "$target"
                substitute "$desktop" "$target" \
                  --replace-fail "Exec=packettracer9" "Exec=$out/bin/packettracer9"
              done
            '';
          }
      )
    ];
  };
}
