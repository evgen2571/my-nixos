{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.system.services.networkNamespaces;

  # Each entry defines one namespace and its WireGuard transport.
  namespaceType = lib.types.submodule {
    options = {
      shared = {
        role = lib.mkOption {
          type = lib.types.enum [
            "standalone"
            "gateway"
            "client"
          ];
          default = "standalone";
        };

        address = lib.mkOption {
          type = lib.types.str;
          default = "10.77.0.1/24";
        };

        address6 = lib.mkOption {
          type = lib.types.str;
          default = "fd77::1/64";
        };

        endpoint = lib.mkOption {
          type = lib.types.nullOr (lib.types.strMatching "[0-9.]+:[0-9]+");
          default = null;
          description = "Gateway Tailscale IPv4 and UDP port; required for clients.";
        };

        privateKeyFile = lib.mkOption {
          type = lib.types.str;
          default = "/run/secrets/vpn-wireguard-private-key";
          description = "Root-readable runtime WireGuard private key, normally managed by sops-nix.";
        };

        peers = lib.mkOption {
          default = [ ];
          type = lib.types.listOf (
            lib.types.submodule {
              options = {
                publicKey = lib.mkOption { type = lib.types.strMatching "[A-Za-z0-9+/]{43}="; };
                allowedIPs = lib.mkOption { type = lib.types.listOf lib.types.str; };
              };
            }
          );
        };
      };

      enable = lib.mkEnableOption "this isolated VPN namespace";

      provider = lib.mkOption {
        type = lib.types.enum [ "hide-me" ];
        default = "hide-me";
        description = "VPN provider; uses the official hide.me CLI.";
      };

      killSwitch = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Required independent underlay filter and provider kill switch.";
      };

      server = lib.mkOption {
        type = lib.types.strMatching "[a-zA-Z0-9][a-zA-Z0-9.-]*";
        default = "free-nl";
        description = "hide.me server short name or FQDN. Free accounts must select a Free server.";
      };

      egressProbeUrls = lib.mkOption {
        type = lib.types.listOf (lib.types.strMatching "https://[^[:space:]]+");
        default = [
          "https://api.github.com/"
          "https://www.cloudflare.com/cdn-cgi/trace"
        ];
        description = ''
          HTTPS endpoints checked periodically from inside the VPN namespace.
          A recent successful probe is required to launch registered applications.
          Probe success does not guarantee every remote API is reachable.
        '';
      };

      bootstrapTokenFile = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "/run/secrets/hide-me-bootstrap";
        description = ''
          Optional runtime secret path, for example a SOPS-Nix secret. A changed
          bootstrap seed replaces the mutable token; unchanged seeds preserve refreshes.
          The client refreshes its writable
          /var/lib/hide-me-NAME/accessToken.txt, never the bootstrap secret.
        '';
      };
    };
  };

  # Only enabled entries produce services and runtime files.
  active = lib.filterAttrs (_: ns: ns.enable) cfg.namespaces;

  instances = lib.mapAttrs (
    name: ns:
    import ./namespace.nix {
      inherit
        config
        lib
        pkgs
        name
        ns
        ;
    }
  ) active;
in
{
  imports = [
    ./launcher.nix
    ./shared.nix
  ];

  options.my.system.services.networkNamespaces = {
    enable = lib.mkEnableOption "isolated VPN namespaces for selected applications";

    namespaces = lib.mkOption {
      type = lib.types.attrsOf namespaceType;
      default = { };
      description = "Persistent network namespaces, each with independent provider state and DNS.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = lib.mapAttrsToList (name: ns: {
      assertion =
        builtins.match "[a-zA-Z][a-zA-Z0-9_-]{0,31}" name != null
        && ns.killSwitch
        && ns.egressProbeUrls != [ ]
        && (
          ns.bootstrapTokenFile == null
          || (lib.hasPrefix "/" ns.bootstrapTokenFile && !lib.hasPrefix "/nix/store/" ns.bootstrapTokenFile)
        );

      message = "Network namespace ${name}: use a safe name, enable killSwitch, configure HTTPS egress probes, and keep bootstrap credentials outside the Nix store.";
    }) active;

    boot.kernelModules = [
      "wireguard"
      "tun"
    ];

    environment.systemPackages =
      lib.optional (lib.any (ns: ns.shared.role != "client") (lib.attrValues active)) (
        pkgs.callPackage ../../../pkgs/hide-me { }
      )
      ++ lib.concatMap (instance: instance.environment.systemPackages) (lib.attrValues instances);

    environment.etc = lib.mkMerge (
      lib.mapAttrsToList (_: instance: instance.environment.etc) instances
    );

    systemd.services = lib.mkMerge (
      lib.mapAttrsToList (
        _: instance:
        lib.mkMerge [
          instance.systemd.services
          instance.systemd.lifecycleServices
        ]
      ) instances
    );

    systemd.timers = lib.mkMerge (lib.mapAttrsToList (_: instance: instance.systemd.timers) instances);
  };
}
