{ pkgs, root }:
let
  actual = import ./catalog.nix { inherit root; };
  baseline = builtins.fromJSON (builtins.readFile ./catalog-baseline.json);
  inventory = builtins.fromJSON (builtins.readFile (root + "/docs/refactor/inventory.json"));
  migrations = builtins.fromJSON (builtins.readFile (root + "/docs/refactor/migrations.json"));
  migrated = migrations.entries;
  mapping = builtins.listToAttrs (
    map (entry: {
      name = entry.path;
      value = if builtins.elem entry.path migrated then entry.target else entry.path;
    }) inventory.entries
  );
  expected = {
    modules = map (
      entry:
      entry
      // {
        path = mapping.${entry.path};
        relPath =
          if builtins.elem entry.path migrated then
            "/${builtins.head (builtins.match "(modules/[^/]+)/.*" mapping.${entry.path})}"
          else
            entry.relPath;
      }
    ) baseline.modules;
    profiles = builtins.mapAttrs (
      _: scopes: builtins.mapAttrs (_: paths: map (path: mapping.${path}) paths) scopes
    ) baseline.profiles;
  };
in
assert builtins.all (path: builtins.hasAttr path mapping) migrated;
assert builtins.all (
  path:
  builtins.hasAttr path inventory.explicit
  && builtins.pathExists (root + "/${inventory.explicit.${path}}")
  && !(builtins.pathExists (root + "/${path}"))
) migrations.explicit;
assert actual == expected;
pkgs.runCommand "module-equivalence-checks" { nativeBuildInputs = [ pkgs.python3 ]; } ''
  cp ${./compare.py} compare.py
  cp ${./test_compare.py} test_compare.py
  python3 test_compare.py
  touch $out
''
