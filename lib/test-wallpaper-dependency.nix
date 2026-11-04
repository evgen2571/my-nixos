# Run: nix-instantiate --eval --strict --read-write-mode lib/test-wallpaper-dependency.nix
let
  desktop = import ../modules/desktop/noctalia/home.nix {
    config.my.user.desktop.noctalia.enable = true;
    configPaths = { };
    lib.mkIf = _: value: value;
    pkgs = { };
    packageSources = { };
    # Use a harmless directory to check retention, without fetching wallpapers.
    inputs.wallpapers.outPath = toString ../templates/private;
  };
  dependencies = desktop.config.home.extraDependencies or [ ];
in
assert dependencies != [ ];
assert builtins.all builtins.hasContext dependencies;
assert builtins.all (path: builtins.pathExists (path + "/flake.nix")) dependencies;
true
