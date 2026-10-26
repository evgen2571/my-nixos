{
  config,
  inputs,
  lib,
  pkgs,
  osConfig ? { },
  ...
}:

let
  cfg = config.my.user.apps.zenBrowser;
  defaults = import ../../config/zen/profile.nix;
  proxy =
    osConfig.my.system.services.browserVpnProxy or {
      enable = false;
      port = 1080;
    };
  pac = pkgs.writeText "zen-vpn-proxy.pac" (
    import ../../config/zen/vpn-proxy.pac.nix {
      inherit (cfg.vpnProxy) domains;
      inherit (proxy) port;
    }
  );
in
{
  imports = [
    inputs.zen-browser.homeModules.beta
  ];

  options.my.user.apps.zenBrowser = {
    enable = lib.mkEnableOption "Zen Browser";

    vpnProxy = {
      enable = lib.mkEnableOption "selective website routing through the system browser VPN proxy";
      domains = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [ "example.com" ];
        description = "Lowercase ASCII domains (punycode for IDNs), including all subdomains.";
      };
    };

    profilePath = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "abcdefgh.Default Profile";
      description = ''
        Existing Zen profile directory name (relative to ~/.config/zen).
        Set this only after checking about:profiles on this host. A null
        value leaves the current browser profile unmanaged.
      '';
    };
  };

  config = lib.mkMerge [
    {
      assertions = lib.optional cfg.vpnProxy.enable {
        assertion =
          cfg.enable
          && cfg.profilePath != null
          && proxy.enable
          && lib.all (
            domain:
            builtins.stringLength domain <= 253
            &&
              builtins.match "[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?(\\.[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?)+" domain
              != null
            && builtins.match "[0-9.]+" domain == null
          ) cfg.vpnProxy.domains;
        message = "Zen vpnProxy requires Zen, an existing profilePath, the system browserVpnProxy, and bare lowercase DNS domains.";
      };
    }
    (lib.mkIf cfg.enable {
      programs.zen-browser = {
        enable = true;

        profiles = lib.mkIf (cfg.profilePath != null) {
          default = defaults // {
            path = cfg.profilePath;
            isDefault = true;
            settings =
              defaults.settings
              // lib.optionalAttrs cfg.vpnProxy.enable {
                "network.proxy.type" = 2;
                "network.proxy.autoconfig_url" = "file://${pac}";
                # Firefox uses separate preferences for SOCKS4 and SOCKS5 DNS.
                "network.proxy.socks5_remote_dns" = true;
                "network.proxy.failover_direct" = false;
                "network.proxy.retry_failed_proxies" = true;
                "network.proxy.allow_bypass" = false;
                "network.dns.disablePrefetch" = true;
                "network.prefetch-next" = false;
                "network.http.speculative-parallel-limit" = 0;
                "media.peerconnection.ice.proxy_only" = true;
              };
          };
        };
      };
    })
  ];
}
