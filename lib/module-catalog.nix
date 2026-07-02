{ root }:
let
  inherit (builtins)
    attrNames
    elem
    filter
    foldl'
    head
    isAttrs
    isList
    listToAttrs
    map
    tail
    ;

  discovery = import ./module-discovery.nix { inherit root; };

  recursiveUpdate =
    lhs: rhs:
    lhs
    // listToAttrs (
      map (
        name:
        let
          lhsValue = lhs.${name} or null;
          rhsValue = rhs.${name};
        in
        {
          inherit name;
          value =
            if isAttrs lhsValue && isAttrs rhsValue then
              recursiveUpdate lhsValue rhsValue
            else
              rhsValue;
        }
      ) (attrNames rhs)
    );

  setAttrPath =
    attrPath: value:
    if attrPath == [ ] then
      value
    else
      {
        ${head attrPath} = setAttrPath (tail attrPath) value;
      };

  module =
    attrPath: path: scope: category: profiles: description:
    {
      inherit
        attrPath
        path
        scope
        category
        profiles
        description
        ;
      discovered = false;
    };

  systemModule = attrPath: relPath: category: profiles: description:
    module attrPath (root + relPath) "system" category profiles description;

  hostBaseEntries = [
    # Host-base modules are imported directly by hosts/*/configuration.nix.
    (systemModule [ "system" "common" ] "/modules/system-core/common.nix" "core" [ ] "Shared desktop NixOS baseline.")
    (systemModule [ "system" "server" ] "/modules/system-core/server.nix" "core" [ ] "Shared server NixOS baseline.")
    (systemModule [ "system" "user" ] "/modules/system-core/user.nix" "core" [ ] "Primary-user and Home Manager wiring.")
  ];

  # Import/discover modules by hierarchy, but keep activation explicit: modules
  # still need per-host/profile enable options to affect the generated system.
  discoveredEntries =
    discovery.systemRoot "/modules/desktops" "desktop" [ "desktop" ] [
      "/modules/desktops/role.nix"
    ]
    ++ discovery.systemRoot "/modules/system-services" "service" [
      "desktop"
      "server"
    ] [ ]
    ++ discovery.systemRoot "/modules/hardware" "hardware" [ "desktop" ] [ ]
    ++ discovery.systemRoot "/modules/system-apps" "app" [ "desktop" ] [ ]
    ++ discovery.systemRoot "/modules/system-dev" "development" [ "desktop" ] [ ]
    ++ discovery.systemRoot "/modules/system-files" "files" [ "desktop" ] [ ]
    ++ discovery.homeRoot "/modules/user-ai" "ai" [ "desktop" ] [ ]
    ++ discovery.homeRoot "/modules/user-apps" "app" [ "desktop" ] [ ]
    ++ discovery.homeRoot "/modules/user-desktop" "desktop" [ "desktop" ] [ ]
    ++ discovery.homeRoot "/modules/user-dev" "development" [
      "desktop"
      "server"
    ] [ ]
    ++ discovery.homeRoot "/modules/user-files" "files" [ "desktop" ] [ ];

  entries = hostBaseEntries ++ discoveredEntries;

  entryForProfile = profile: scope: entry:
    entry.scope == scope && elem profile entry.profiles;

  entriesFor = profile: scope:
    filter (entryForProfile profile scope) entries;

  pathsFor = profile: scope:
    map (entry: entry.path) (entriesFor profile scope);

  profileImports = profile: {
    systemModules = pathsFor profile "system";
    homeModules = pathsFor profile "home";
  };

  hasAttrPath = entry: isList entry.attrPath;

  paths = foldl' (
    acc: entry:
    if hasAttrPath entry then
      recursiveUpdate acc (setAttrPath entry.attrPath entry.path)
    else
      acc
  ) { } entries;
in
{
  inherit
    discoveredEntries
    entries
    entriesFor
    hostBaseEntries
    paths
    pathsFor
    profileImports
    ;

  profiles = {
    desktop = profileImports "desktop";
    server = profileImports "server";
  };
}
