# Implementation helper, imported only by namespace.nix.
{
  config,
  lib,
  pkgs,
  name,
  ns,
}:
let
  dependencies = {
    "netns-${name}.service" = [ ];
    "netns-${name}-shared.service" = [ "netns-${name}.service" ];
  }
  // lib.optionalAttrs (ns.shared.role == "gateway") {
    "netns-${name}-underlay.service" = [ "netns-${name}.service" ];
    "hide-me-${name}.service" = [ "netns-${name}.service" ];
    "netns-${name}-dns.service" = [
      "netns-${name}.service"
      "netns-${name}-shared.service"
    ];
  };
  settings = pkgs.writeText "netns-${name}-doctor.json" (
    builtins.toJSON {
      inherit name dependencies;
      namespace_path = "/run/netns/${name}";
      host = config.networking.hostName;
      role = ns.shared.role;
      runtime = "/run/network-namespaces/${name}";
      state = "/var/lib/network-namespaces-${name}";
      key = ns.shared.privateKeyFile;
      bootstrap = ns.bootstrapTokenFile;
      token = "/var/lib/hide-me-${name}/accessToken.txt";
      endpoint =
        if ns.shared.endpoint == null then null else builtins.head (lib.splitString ":" ns.shared.endpoint);
      peers = map (p: p.publicKey) ns.shared.peers;
      urls = ns.egressProbeUrls;
    }
  );
  command = pkgs.writeShellApplication {
    name = "netns-${name}-doctor";
    runtimeInputs = with pkgs; [
      python3
      coreutils
      systemd
      iproute2
      nftables
      wireguard-tools
      tailscale
      curl
      bind
      procps
    ];
    text = ''
      exec python3 ${./doctor.py} ${settings} "$@"
    '';
  };
  wrapper =
    suffix: mode:
    pkgs.writeShellScript "netns-${name}-${suffix}" ''
      exec ${lib.getExe command} ${mode} "$@"
    '';
in
{
  inherit command;
  services = lib.mapAttrs' (
    unit: _:
    lib.nameValuePair (lib.removeSuffix ".service" unit) {
      serviceConfig = {
        # Fixed root-only hooks record lifecycle cause outside the service sandbox.
        ExecStartPre = lib.mkBefore [ "+${lib.getExe command} lifecycle-start ${unit}" ];
        ExecStopPost = lib.mkAfter [ "+${lib.getExe command} lifecycle-stop ${unit}" ];
      };
    }
  ) dependencies;
  probe = wrapper "probe" "probe";
  reconcile = wrapper "reconcile" "reconcile";
  gate = wrapper "provider-allowed" "provider-allowed";
  reset = wrapper "recovery-reset" "reset";
  status = pkgs.writeShellApplication {
    name = if name == "vpn" then "vpn-status" else "${name}-vpn-status";
    text = ''exec ${lib.getExe command} status "$@"'';
  };
}
