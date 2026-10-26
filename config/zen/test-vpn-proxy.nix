# nix-build config/zen/test-vpn-proxy.nix --no-out-link
{
  inputs ? (builtins.getFlake (toString ../..)).inputs,
  pkgs ? import inputs.nixpkgs { system = "x86_64-linux"; },
}:
let
  inherit (pkgs) lib;
  home =
    overrides:
    (inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = {
        inherit inputs;
        osConfig.my.system.services.browserVpnProxy = {
          enable = true;
          port = 1080;
        };
      };
      modules = [
        ../../modules/apps/zen-browser.home.nix
        {
          home = {
            username = "test-user";
            homeDirectory = "/home/test-user";
            stateVersion = "25.11";
          };
          my.user.apps.zenBrowser = {
            enable = true;
            profilePath = "existing.profile";
            vpnProxy = {
              enable = true;
              domains = lib.mkDefault [ "example.com" ];
            };
          };
        }
        overrides
      ];
    }).config;
  enabled = home { };
  disabled = home { my.user.apps.zenBrowser.vpnProxy.enable = lib.mkForce false; };
  invalid = domain: home { my.user.apps.zenBrowser.vpnProxy.domains = [ domain ]; };
  missingProfile = home { my.user.apps.zenBrowser.profilePath = lib.mkForce null; };
  valid = c: lib.all (a: a.assertion) c.assertions;
  profile = enabled.programs.zen-browser.profiles.default;
  settings = profile.settings;
  pac = lib.removePrefix "file://" settings."network.proxy.autoconfig_url";
in
assert valid enabled;
assert valid disabled;
assert !(builtins.tryEval missingProfile).success;
assert lib.all (domain: !(builtins.tryEval (invalid domain)).success) [
  "https://example.com"
  "*.example.com"
  "example.com/path"
  "Example.com"
  "example.com; DIRECT"
  "127.0.0.1"
  "-bad.test"
  "bad-.test"
  "example.com."
];
assert profile.path == "existing.profile";
assert profile.settings."browser.startup.page" == 3;
assert !profile.spacesForce && !profile.pinsForce && !profile.spaceRouting.force;
assert !(disabled.programs.zen-browser.profiles.default.settings ? "network.proxy.type");
assert settings."network.proxy.type" == 2;
assert settings."network.proxy.socks5_remote_dns";
assert !settings."network.proxy.failover_direct";
assert settings."network.proxy.retry_failed_proxies";
assert !settings."network.proxy.allow_bypass";
assert settings."network.dns.disablePrefetch";
pkgs.runCommand "zen-vpn-pac-tests" { nativeBuildInputs = [ pkgs.nodejs ]; } ''
  node ${./test-vpn-proxy.js} ${pac}
  touch $out
''
