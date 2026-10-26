# nix-build config/umbriel/test-module.nix --no-out-link
{
  inputs ? (builtins.getFlake ("git+file://" + toString ../..)).inputs,
  pkgs ? import inputs.nixpkgs { system = "x86_64-linux"; },
}:
let
  inherit (pkgs) lib;
  configPaths = import ../../lib/config-paths.nix {
    root = ../..;
    inherit lib;
  };
  home =
    enabled: sonora:
    (inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = {
        inherit inputs configPaths;
        packageSources.noctalia = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
      };
      modules = [
        ../../modules/desktop/umbriel/home.nix
        ../../modules/desktop/noctalia/home.nix
        {
          options.my.user.apps.sonora.enable = lib.mkEnableOption "test music player";
          config = {
            home = {
              username = "test-user";
              homeDirectory = "/home/test-user";
              stateVersion = "25.11";
            };
            my.user.desktop = {
              umbrielConfig.enable = enabled;
              noctalia.enable = true;
            };
            my.user.apps.sonora.enable = sonora;
          };
        }
      ];
    }).config;
  enabledHome = home true true;
  disabledHome = home false false;
  fallbackHome = home true false;
  system = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      ../../modules/desktop/umbriel/nixos.nix
      {
        my.desktop.umbriel.enable = true;
        system.stateVersion = "25.11";
      }
    ];
  };
  disabledSystem =
    (system.extendModules {
      modules = [ { my.desktop.umbriel.enable = lib.mkForce false; } ];
    }).config;
  enabledSystem = system.config;
  files = enabledHome.xdg.configFile;
in
assert enabledSystem.programs.umbriel.enable;
assert builtins.elem enabledSystem.programs.umbriel.package
  enabledSystem.services.displayManager.sessionPackages;
assert enabledSystem.xdg.portal.config.umbriel.default == "umbriel;gtk";
assert !disabledSystem.programs.umbriel.enable;
assert !(disabledSystem.systemd.user.services ? polkit-gnome-authentication-agent-1);
assert files ? "umbriel/config.toml";
assert files ? "umbriel/scratchpads.toml";
assert !(files ? "umbriel/noctalia.toml");
assert !(disabledHome.xdg.configFile ? "umbriel/config.toml");
assert builtins.elem "umbriel" enabledHome.programs.noctalia.settings.theme.templates.builtin_ids;
assert !(builtins.elem "niri" enabledHome.programs.noctalia.settings.theme.templates.builtin_ids);
assert !enabledHome.programs.noctalia.settings.theme.templates.user.niri-layout.enabled;
assert builtins.elem "niri" disabledHome.programs.noctalia.settings.theme.templates.builtin_ids;
pkgs.runCommand "umbriel-config-tests" { } ''
  mkdir -p "$out"
  ${lib.concatMapStringsSep "\n"
    (name: ''
      cp ${files."umbriel/${name}".source} "$out/${name}"
    '')
    [
      "config.toml"
      "binds.toml"
      "rules.toml"
      "scratchpads.toml"
    ]
  }
  grep -q 'spawn_when_empty = "sonora"' "$out/scratchpads.toml"
  grep -q 'spawn_when_empty = "pear-desktop"' ${
    fallbackHome.xdg.configFile."umbriel/scratchpads.toml".source
  }
  ${lib.getExe enabledSystem.programs.umbriel.package} config validate -c "$out/config.toml"
''
