let
  select = import ../../lib/secret-source.nix;
  root = ./fixtures;

  private = {
    nixosModules.pc = { };
    secretFiles.pc = ./fixtures/valid.yaml;
  };

  none = select {
    inherit root private;
    host = "pc";
    source = "none";
  };

  empty = select {
    inherit root;
    private = { };
    host = "pc";
    source = "private";
  };

  local = select {
    inherit root private;
    host = "pc";
    source = "local";
  };

  personal = select {
    inherit root private;
    host = "pc";
    source = "private";
  };

  fails = args: !(builtins.tryEval (builtins.deepSeq (select args) true)).success;
in
assert
  (select {
    inherit root;
    private = throw "unselected input forced";
    host = "pc";
    source = "none";
  }).file == null;
assert fails {
  inherit root;

  private = {
    secretFiles.pc = null;
  };

  host = "pc";
  source = "private";
};
assert fails {
  inherit root;

  private = {
    nixosModules.pc = { };
  };

  host = "pc";
  source = "private";
};
assert none.file == null && none.modules == [ ];
assert empty.file == null && empty.modules == [ ];
assert local.file == root + /secrets/hosts/pc.yaml && local.modules == [ ];
assert personal.file == private.secretFiles.pc && personal.modules == [ { } ];
assert fails {
  inherit root private;
  host = "pc";
  source = "typo";
};
assert fails {
  inherit root;

  private = {
    secretFiles.pc = /nonexistent;
  };

  host = "pc";
  source = "private";
};
assert fails {
  inherit root;

  private = {
    secretFiles = [ ];
  };

  host = "pc";
  source = "private";
};
assert fails {
  inherit root;
  private = { };
  host = "absent";
  source = "local";
};
true
