# nix-build config/noctalia/test-config.nix --no-out-link
{
  inputs ? (builtins.getFlake (toString ../..)).inputs,
  pkgs ? import inputs.nixpkgs { system = "x86_64-linux"; },
}:
let
  inherit (pkgs) lib;
  configPaths = import ../../lib/config-paths.nix {
    root = ../..;
    inherit lib;
  };
  home =
    modules:
    (inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = {
        inherit inputs configPaths;
        packageSources.noctalia = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
      };
      modules = [
        ../../modules/desktop/noctalia/home.nix
        {
          home = {
            username = "test-user";
            homeDirectory = "/home/test-user";
            stateVersion = "25.11";
          };
          my.user.desktop.noctalia.enable = lib.mkDefault true;
        }
      ]
      ++ modules;
    }).config;
  portable = home [ ];
  collection = home [ { wallpapers.enable = true; } ];
  disabled = home [ { my.user.desktop.noctalia.enable = false; } ];
  legacyPC = home [ { my.user.desktop.noctalia.profile = "pc"; } ];
  legacyLaptop = home [ { my.user.desktop.noctalia.profile = "laptop"; } ];
  pc = home [
    {
      programs.noctalia.settings.include.files = [ "${./widgets-pc.toml}" ];
    }
    # A separate module, like a private host override.
    {
      programs.noctalia.settings.desktop_widgets.widget.desktop-widget-0000000000000001 = {
        type = "clock";
        cx = 400.0;
      };
    }
  ];
  overrides = home [
    {
      programs.noctalia-shell.settings.widget.volume.enabled = false;
      programs.noctalia.settings = {
        bar.default.end = [ "clock" ];
        widget.clock.scale = 1.3;
        widget.battery.enabled = false;
        wallpaper.directory = "/home/test-user/wallpapers";
        theme.templates.user.nvim-base16.enabled = true;
      };
    }
  ];
  custom = home [
    {
      my.user.desktop.noctalia.configFile = builtins.toFile "custom-noctalia.toml" ''
        [bar.default]
        thickness = 30
        [theme]
        mode = "light"
      '';
    }
  ];
in
assert portable.my.user.desktop.noctalia.profile == null;
assert portable.programs.noctalia.enable && portable.programs.noctalia.systemd.enable;
assert portable.programs.noctalia.checkConfig;
assert builtins.elem "battery" portable.programs.noctalia.settings.bar.default.end;
assert builtins.elem "brightness" portable.programs.noctalia.settings.bar.default.end;
assert !(portable.programs.noctalia.settings ? desktop_widgets);
assert !(portable.programs.noctalia.settings ? lockscreen_widgets);
assert !portable.programs.noctalia.settings.theme.templates.user.nvim-base16.enabled;
assert !portable.programs.noctalia.settings.theme.templates.user.niri-layout.enabled;
assert portable.fonts.fontconfig.enable;
assert builtins.elem pkgs.nerd-fonts.hurmit portable.home.packages;
assert portable.wallpapers.directory == "/home/test-user/pictures/wallpapers";
assert collection.home.file.wallpapers.target == "pictures/wallpapers";
assert collection.home.file.wallpapers.recursive && !collection.home.file.wallpapers.force;
assert collection.programs.noctalia.settings.wallpaper.directory == collection.wallpapers.directory;
assert portable.programs.noctalia.settings.theme.source == "wallpaper";
assert !(disabled.xdg.configFile ? "noctalia/config.toml");
assert !(disabled.home.activation ? pruneStaleNoctaliaSettings);
assert legacyPC.programs.noctalia.settings.desktop_widgets.enabled;
assert
  legacyPC.programs.noctalia.settings.desktop_widgets.widget.desktop-widget-0000000000000001.output
  == "HDMI-A-1";
assert legacyLaptop.programs.noctalia.settings == portable.programs.noctalia.settings;
assert
  pc.programs.noctalia.settings.desktop_widgets.widget.desktop-widget-0000000000000001.cx == 400.0;
assert overrides.programs.noctalia.settings.bar.default.end == [ "clock" ];
assert overrides.programs.noctalia.settings.widget.clock.scale == 1.3;
assert !overrides.programs.noctalia.settings.widget.battery.enabled;
assert !overrides.programs.noctalia.settings.widget.volume.enabled;
assert overrides.wallpapers.directory == "/home/test-user/wallpapers";
assert overrides.programs.noctalia.settings.theme.templates.user.nvim-base16.enabled;
assert custom.programs.noctalia.settings.bar.default.thickness == 30;
assert custom.programs.noctalia.settings.theme.mode == "light";
pkgs.runCommand "noctalia-config-tests" { } ''
  mkdir -p "$out"
  ${lib.concatStringsSep "\n" (
    lib.mapAttrsToList
      (name: config: ''
        mkdir -p "${name}/config/noctalia"
        cp ${config.xdg.configFile."noctalia/config.toml".source} "${name}/config/noctalia/config.toml"
        export NOCTALIA_CONFIG_HOME="$PWD/${name}/config"
        export NOCTALIA_STATE_HOME="$PWD/${name}/state"
        export NOCTALIA_DATA_HOME="$PWD/${name}/data"
        ${lib.getExe config.programs.noctalia.package} config validate "$NOCTALIA_CONFIG_HOME/noctalia"
        ${lib.getExe config.programs.noctalia.package} config export full > "$out/${name}.toml"
      '')
      {
        inherit
          portable
          legacyPC
          legacyLaptop
          pc
          overrides
          custom
          ;
      }
  )}
  mkdir -p "$NOCTALIA_STATE_HOME/noctalia"
  cat > "$NOCTALIA_STATE_HOME/noctalia/settings.toml" <<'TOML'
  [theme]
  mode = "light"
  [widget.clock]
  scale = 1.7
  TOML
  ${lib.getExe portable.programs.noctalia.package} config export full > "$out/gui.toml"
  ${pkgs.python3}/bin/python3 - "$out" <<'PY'
  import pathlib, sys, tomllib
  configs = {p.stem: tomllib.loads(p.read_text()) for p in pathlib.Path(sys.argv[1]).glob('*.toml')}
  clock = 'desktop-widget-0000000000000001'
  assert configs['pc']['desktop_widgets']['widget'][clock]['cx'] == 400.0
  assert configs['pc']['desktop_widgets']['widget'][clock]['output'] == 'HDMI-A-1'
  assert configs['pc']['desktop_widgets']['widget'][clock]['settings']['format'] == '{:%I:%M %p} '
  assert not configs['pc']['lockscreen_widgets']['enabled']
  assert 'widget' not in configs['portable']['desktop_widgets']
  assert configs['legacyPC']['desktop_widgets']['widget'][clock]['cx'] == 352.0
  assert configs['gui']['theme']['mode'] == 'light'
  assert configs['gui']['widget']['clock']['scale'] == 1.7
  PY
''
