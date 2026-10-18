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
          my.primaryUser.home.settings.programs.noctalia.settings.location.address =
            lib.mkForce "Example City";
        })
      ];
    }).config;
  home = renamed.home-manager.users.fixture-user;
  partial =
    (desktop.extendModules {
      specialArgs.secretFile = ./fixtures/valid.yaml;
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
  legacy =
    (desktop.extendModules {
      modules = [
        ({ lib, ... }: {
          my.primaryUser.home.settings.my.user.desktop.noctalia.legacyConfig = {
            enable = true;
            settings.location.name = lib.mkForce "Example City";
          };
        })
      ];
    }).config;
  legacyHome = legacy.home-manager.users.${legacy.my.primaryUser.name};
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
assert home.home.username == "fixture-user";
assert home.home.homeDirectory == "/home/fixture-user";
assert renamed.fileSystems ? "/home/fixture-user/drive";
assert home.programs.noctalia.settings.location.address == "Example City";
assert home.programs.noctalia.settings.shell.font_family == "Hurmit Nerd Font";
assert home.programs.noctalia.settings.wallpaper.enabled;
assert rejects "Shared VPN" missingPeer;
assert rejects "Production SSH server" missingKeys;
assert !(builtins.tryEval conflicting.config.my.primaryUser.name).success;
assert !public || rejects "Production private input" partial;
assert lib.all (c: c.system.preSwitchChecks ? privateMaterial) (
  map (host: configurations.${host}.config) [
    "nixos-pc"
    "nixos-lp"
    "nixos-server"
  ]
);
pkgs.runCommand "personal-metadata-checks" { nativeBuildInputs = [ pkgs.python3 ]; } ''
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME"
    ${legacyHome.home.activation.installLegacyNoctaliaConfig.data}
    python3 - <<'PYTEST'
  import json, os, pathlib
  settings = json.loads((pathlib.Path(os.environ['HOME']) / '.config/noctalia/settings.json').read_text())
  assert settings['location']['name'] == 'Example City'
  assert settings['wallpaper']['enabled']
  PYTEST
    touch $out
''
