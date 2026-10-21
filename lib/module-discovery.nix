{ root }:

let
  inherit (builtins)
    attrNames
    concatLists
    map
    match
    pathExists
    readDir
    ;

  scopeOf =
    name:
    if name == "nixos.nix" || match ".*\\.nixos\\.nix" name != null then
      "system"
    else if name == "home.nix" || match ".*\\.home\\.nix" name != null then
      "home"
    else
      null;

  scan =
    dir:
    let
      entries = readDir dir;
    in
    concatLists (
      map (
        name:
        let
          kind = entries.${name};
          path = dir + "/${name}";
          scope = scopeOf name;
        in
        if kind == "directory" then
          scan path
        else if kind != "regular" then
          [ ]
        else if scope != null then
          [ { inherit path scope; } ]
        else
          [ ]
      ) (attrNames entries)
    );

  under =
    relPath:
    let
      dir = root + relPath;
    in
    if pathExists dir then scan dir else [ ];
in
{
  typedUnder = under;
}
