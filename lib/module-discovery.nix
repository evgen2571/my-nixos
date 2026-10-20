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
    legacy: dir:
    let
      entries = readDir dir;
    in
    if legacy && entries."default.nix" or null == "regular" then
      [ dir ]
    else
      concatLists (
        map (
          name:
          let
            kind = entries.${name};
            path = dir + "/${name}";
            scope = scopeOf name;
          in
          if kind == "directory" then
            scan legacy path
          else if kind != "regular" then
            [ ]
          else if legacy then
            if scope == null && match ".*\\.nix" name != null then [ path ] else [ ]
          else if scope != null then
            [ { inherit path scope; } ]
          else
            [ ]
        ) (attrNames entries)
      );

  under =
    legacy: relPath:
    let
      dir = root + relPath;
    in
    if pathExists dir then scan legacy dir else [ ];
in
{
  modulesUnder = under true;
  typedUnder = under false;
}
