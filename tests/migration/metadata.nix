# Evaluate the public module interfaces; no real identity or runtime state needed.
{ configurations, pkgs }:

let
  lib = pkgs.lib;
  desktop = configurations.nixos-pc;
  public = !(desktop.config.sops.secrets ? user-password);

  renamed =
    (desktop.extendModules {
      modules = [
        ({ lib, ... }: {
          my.primaryUser.name = lib.mkForce "fixture-user";
          time.timeZone = lib.mkForce "Etc/GMT+3";
          my.primaryUser.home.settings.programs.ssh.settings.server.User = lib.mkForce "fixture-remote";

          my.primaryUser.home.settings.programs.noctalia.settings.location.address =
            lib.mkForce "Example City";
          my.primaryUser.home.settings.programs.noctalia.settings.wallpaper.directory =
            lib.mkForce "/home/fixture-user/Collection";
        })
      ];
    }).config;

  home = renamed.home-manager.users.fixture-user;

  devices = lib.mapAttrs (
    _: host:
    (host.extendModules {
      modules = [
        (
          { ... }:
          {
            fileSystems = lib.mapAttrs (_: _: {
              device = lib.mkOverride 40 "/dev/disk/by-label/FIXTURE";
            }) host.config.fileSystems;
            swapDevices = lib.mkOverride 40 [ { device = "/dev/disk/by-label/FIXTURE-SWAP"; } ];
          }
          // lib.optionalAttrs (host.config.my ? server) {
            my.server.storage.device = lib.mkOverride 40 "/dev/disk/by-label/FIXTURE";
          }
        )
      ];
    }).config
  ) configurations;

  adopted =
    (desktop.extendModules {
      modules = [
        {
          my.primaryUser.home.settings = {
            my.user.apps.zenBrowser.profilePath = lib.mkOverride 40 "fixture.default";
            programs.zen-browser.profiles.default = {
              spaces.Fixture = {
                id = lib.mkOverride 40 "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa";
                pins.Example = {
                  id = "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb";
                  url = "https://example.invalid/";
                };
                routes.Example.reference = "example.invalid";
              };
            };
          };
        }
      ];
    }).config;
  browser =
    adopted.home-manager.users.${adopted.my.primaryUser.name}.programs.zen-browser.profiles.default;

  sharedBrowser = import ../../config/zen/profile.nix;

  partial =
    (desktop.extendModules {
      specialArgs.secretFile = ./fixtures/valid.yaml;
    }).config;

  exampleDevice =
    (desktop.extendModules {
      specialArgs.secretFile = ./fixtures/valid.yaml;
      modules = [
        {
          fileSystems."/".device = lib.mkOverride 40 "/dev/disk/by-label/MY-NIXOS-PC-ROOT-REPLACE-ME";
        }
      ];
    }).config;

  missingPeer =
    (desktop.extendModules {
      modules = [
        ({ lib, ... }: {
          my.system.services.networkNamespaces.namespaces.vpn.shared.peers = lib.mkForce [ ];
        })
      ];

      specialArgs.secretFile = ./fixtures/valid.yaml;
    }).config;

  missingKeys =
    (configurations.nixos-server.extendModules {
      specialArgs.secretFile = ./fixtures/valid.yaml;

      modules = [
        ({ lib, ... }: {
          my.primaryUser = {
            name = lib.mkForce "fixture-user";
            authorizedKeys = lib.mkForce [ ];
            authorizedKeyFiles = lib.mkForce [ ];
          };
        })
      ];
    }).config;

  conflicting = desktop.extendModules {
    modules = [
      { my.primaryUser.name = "first-user"; }
      { my.primaryUser.name = "second-user"; }
    ];
  };

  rejects = prefix: c: lib.any (a: !a.assertion && lib.hasPrefix prefix a.message) c.assertions;
in
assert !public || desktop.config.my.primaryUser.name == "operator";
assert !public || lib.all (c: c.config.time.timeZone == "UTC") (builtins.attrValues configurations);
assert
  !public
  || desktop.config.home-manager.users.operator.programs.ssh.settings.server.data.User == "operator";
assert renamed.time.timeZone == "Etc/GMT+3";
assert home.programs.ssh.settings.server.data.User == "fixture-remote";
assert home.home.username == "fixture-user";
assert home.home.homeDirectory == "/home/fixture-user";
assert !(sharedBrowser ? spaces || sharedBrowser ? pins);
assert browser.settings."browser.startup.page" == 3;
assert !browser.settings."zen.pinned-tab-manager.restore-pinned-tabs-to-pinned-url";
assert browser.settings."zen.pinned-tab-manager.close-shortcut-behavior" == "unload-switch";
assert !browser.spacesForce && !browser.pinsForce && !browser.spaceRouting.force;
assert renamed.fileSystems ? "/home/fixture-user/drive";
assert lib.all (
  c: lib.all (fs: fs.device == "/dev/disk/by-label/FIXTURE") (builtins.attrValues c.fileSystems)
) (builtins.attrValues devices);
assert lib.all (c: map (s: s.device) c.swapDevices == [ "/dev/disk/by-label/FIXTURE-SWAP" ]) (
  builtins.attrValues devices
);
assert devices.nixos-server.my.server.storage.device == "/dev/disk/by-label/FIXTURE";
assert browser.path == "fixture.default";
assert lib.any (s: s.uuid == "{aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa}") browser.sessionStore.spaces;
assert lib.any (
  p:
  p.zenSyncId == "{bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb}"
  && p.zenWorkspace == "{aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa}"
) browser.sessionStore.tabs;
assert
  browser.spaceRouting.routes."spaces/Fixture/Example".openIn
  == "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa";
assert home.programs.noctalia.settings.location.address == "Example City";
assert home.programs.noctalia.settings.shell.font_family == "Hurmit Nerd Font";
assert home.programs.noctalia.settings.wallpaper.enabled;
assert home.wallpapers.enable;
assert home.wallpapers.directory == home.programs.noctalia.settings.wallpaper.directory;
assert home.home.file.wallpapers.target == "Collection";
assert rejects "Shared VPN" missingPeer;
assert rejects "Production SSH server" missingKeys;
assert !(builtins.tryEval conflicting.config.my.primaryUser.name).success;
assert !public || rejects "Production private input" partial;
assert rejects "Production private input must supply real filesystem devices" exampleDevice;
assert lib.all (c: c.system.preSwitchChecks ? privateMaterial) (
  map (host: configurations.${host}.config) [
    "nixos-pc"
    "nixos-lp"
    "nixos-server"
  ]
);
pkgs.runCommand "personal-metadata-checks" { } "touch $out"
