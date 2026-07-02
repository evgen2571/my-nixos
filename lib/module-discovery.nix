{ root }:
let
  inherit (builtins)
    attrNames
    concatLists
    elem
    filter
    map
    match
    pathExists
    readDir
    ;

  isNixFile = name: match ".*\\.nix" name != null;

  scanDir = dir:
    let
      entries = readDir dir;
      names = attrNames entries;
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
        ) names
      );

  scanRoot = relPath:
    let
      dir = root + relPath;
    in
    if pathExists dir then scanDir dir else [ ];

  prioritizedScan = relPath: priorityRelPaths:
    let
      priorityPaths = filter pathExists (map (path: root + path) priorityRelPaths);
      discoveredPaths = scanRoot relPath;
      remainingPaths = filter (path: !(elem path priorityPaths)) discoveredPaths;
    in
    priorityPaths ++ remainingPaths;

  moduleEntry = scope: category: profiles: path: {
    inherit
      path
      scope
      category
      profiles
      ;
    attrPath = null;
    discovered = true;
    description = "Automatically discovered ${scope} module.";
  };

  systemRoot = relPath: category: profiles: priorityRelPaths:
    map (moduleEntry "system" category profiles) (prioritizedScan relPath priorityRelPaths);

  homeRoot = relPath: category: profiles: priorityRelPaths:
    map (moduleEntry "home" category profiles) (prioritizedScan relPath priorityRelPaths);
in
{
  inherit
    homeRoot
    scanDir
    scanRoot
    systemRoot
    ;
}
