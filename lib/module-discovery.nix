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

  isNixFile = name: match ".*\\.nix" name != null;

  scanDir =
    dir:
    let
      entries = readDir dir;
    in
    if entries ? "default.nix" then
      [ dir ]
    else
      concatLists (
        map (
          name:
          let
            entryType = entries.${name};
            entryPath = dir + "/${name}";
          in
          if entryType == "regular" && isNixFile name then
            [ entryPath ]
          else if entryType == "directory" then
            scanDir entryPath
          else
            [ ]
        ) (attrNames entries)
      );

  modulesUnder =
    relPath:
    let
      dir = root + relPath;
    in
    if pathExists dir then scanDir dir else [ ];
in
{
  inherit modulesUnder;
}
