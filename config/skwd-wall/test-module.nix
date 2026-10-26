# nix-build config/skwd-wall/test-module.nix --no-out-link
{
  inputs ? (builtins.getFlake ("git+file://" + toString ../..)).inputs,
  pkgs ? import inputs.nixpkgs { system = "x86_64-linux"; },
}:
let
  inherit (pkgs) lib;
  package = inputs.skwd-wall.packages.${pkgs.stdenv.hostPlatform.system}.default;
  home =
    overrides:
    (inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = {
        inherit inputs;
        configPaths = import ../../lib/config-paths.nix {
          root = ../..;
          inherit lib;
        };
        packageSources = {
          noctalia = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
          skwd-wall = package;
        };
      };
      modules = [
        ../../modules/desktop/noctalia/home.nix
        ../../modules/desktop/skwd-wall.home.nix
        {
          home = {
            username = "test-user";
            homeDirectory = "/home/test-user";
            stateVersion = "25.11";
          };
          my.user.desktop.noctalia.enable = true;
          my.user.desktop.skwdWall.enable = lib.mkDefault true;
        }
        overrides
      ];
    }).config;
  enabled = home { };
  disabled = home { my.user.desktop.skwdWall.enable = false; };
  custom = home { programs.noctalia.settings.wallpaper.directory = "/custom/wallpapers"; };
  seed =
    config:
    lib.replaceStrings [ "/home/test-user" ] [ "$HOME" ] config.home.activation.seedSkwdWallConfig.data;
in
assert builtins.elem package enabled.home.packages;
assert !enabled.programs.noctalia.settings.wallpaper.enabled;
assert
  enabled.programs.noctalia.settings.widget.wallpaper.actions.left
  == "exec ${package}/bin/skwd-wall-v2";
assert
  enabled.systemd.user.services.skwd-walld.Service.ExecStart == [ "${package}/bin/skwd-walld" ];
assert enabled.systemd.user.services.skwd-walld.Install.WantedBy == [ "graphical-session.target" ];
assert !(disabled.systemd.user.services ? skwd-walld);
assert !(disabled.home.activation ? seedSkwdWallConfig);
assert !(builtins.elem package disabled.home.packages);
assert !(disabled.programs.noctalia.settings.wallpaper ? enabled);
assert
  (builtins.fromTOML (builtins.readFile ../umbriel/binds.toml)).keybinds."Mod+Y"
  == "spawn:skwd-wall-v2";
pkgs.runCommand "skwd-wall-module-tests" { nativeBuildInputs = [ pkgs.python3 ]; } ''
  export HOME="$TMPDIR/home"
  run() { "$@"; }
  ${seed enabled}
  python3 - <<'PY'
  import json, pathlib, stat
  path = pathlib.Path.home() / '.config/skwd-wall-v2/config.json'
  config = json.loads(path.read_text())
  assert config['paths']['wallpaper'] == '/home/test-user/Pictures/Wallpapers'
  assert config['paths']['videoWallpaper'] == config['paths']['wallpaper']
  assert config['theme'] == {'policy': 'wallpaper', 'authority': 'noctalia'}
  assert config['paths']['noctaliaBin'].endswith('/bin/noctalia')
  assert stat.S_IMODE(path.stat().st_mode) == 0o600
  path.write_text('{"gui": "preserved"}')
  PY
  ${seed enabled}
  grep -q '"gui": "preserved"' "$HOME/.config/skwd-wall-v2/config.json"
  rm "$HOME/.config/skwd-wall-v2/config.json"
  ${seed custom}
  python3 - <<'PY'
  import json, pathlib
  config = json.loads((pathlib.Path.home() / '.config/skwd-wall-v2/config.json').read_text())
  assert config['paths']['wallpaper'] == '/custom/wallpapers'
  assert config['paths']['videoWallpaper'] == '/custom/wallpapers'
  PY
  rm "$HOME/.config/skwd-wall-v2/config.json"
  ln -s missing.json "$HOME/.config/skwd-wall-v2/config.json"
  ${seed enabled}
  test "$(readlink "$HOME/.config/skwd-wall-v2/config.json")" = missing.json
  ${package}/bin/skwd-wall-v2 --version
  ${package}/bin/skwd-walld --version
  touch "$out"
''
