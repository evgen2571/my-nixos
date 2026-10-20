{ pkgs, root }:
let
  actual = import ./catalog.nix { inherit root; };
  expected = builtins.fromJSON (builtins.readFile ./catalog-baseline.json);
in
assert actual == expected;
pkgs.runCommand "module-equivalence-checks" { nativeBuildInputs = [ pkgs.python3 ]; } ''
  cp ${./compare.py} compare.py
  cp ${./test_compare.py} test_compare.py
  python3 test_compare.py
  touch $out
''
