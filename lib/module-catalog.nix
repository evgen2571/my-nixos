{ root }:
let
  inherit (builtins)
    concatLists
    elem
    filter
    map
    pathExists
    ;

  discovery = import ./module-discovery.nix { inherit root; };

  profileRoots = [
    {
      scope = "system";
      relPath = "/modules/desktops";
      profiles = [ "desktop" ];
    }
    {
      scope = "system";
      relPath = "/modules/server";
      profiles = [ "server" ];
    }
    {
      scope = "system";
      relPath = "/modules/system-services";
      profiles = [
        "desktop"
        "server"
      ];
    }
    {
      scope = "system";
      relPath = "/modules/hardware";
      profiles = [ "desktop" ];
    }
    {
      scope = "system";
      relPath = "/modules/system-apps";
      profiles = [ "desktop" ];
    }
    {
      scope = "system";
      relPath = "/modules/system-dev";
      profiles = [ "desktop" ];
    }
    {
      scope = "system";
      relPath = "/modules/system-files";
      profiles = [ "desktop" ];
    }
    {
      scope = "home";
      relPath = "/modules/user-ai";
      profiles = [ "desktop" ];
    }
    {
      scope = "home";
      relPath = "/modules/user-apps";
      profiles = [ "desktop" ];
    }
    {
      scope = "home";
      relPath = "/modules/user-desktop";
      profiles = [ "desktop" ];
    }
    {
      scope = "home";
      relPath = "/modules/user-dev";
      profiles = [
        "desktop"
        "server"
      ];
    }
    {
      scope = "home";
      relPath = "/modules/user-files";
      profiles = [ "desktop" ];
    }
  ];

  preferredPaths = rootDef: filter pathExists (map (relPath: root + relPath) (rootDef.first or [ ]));

  orderedDiscoveredPaths =
    rootDef:
    let
      first = preferredPaths rootDef;
      discovered = discovery.modulesUnder rootDef.relPath;
    in
    first ++ filter (path: !(elem path first)) discovered;

  modulesForRoot =
    rootDef:
    map (path: {
      inherit path;
      inherit (rootDef) scope profiles relPath;
    }) (orderedDiscoveredPaths rootDef);

  modules = concatLists (map modulesForRoot profileRoots);

  moduleMatches =
    profile: scope: module:
    module.scope == scope && elem profile module.profiles;

  pathsFor = profile: scope: map (module: module.path) (filter (moduleMatches profile scope) modules);

  profile = name: {
    systemModules = pathsFor name "system";
    homeModules = pathsFor name "home";
  };
in
{
  inherit
    modules
    profileRoots
    ;

  profiles = {
    desktop = profile "desktop";
    server = profile "server";
  };
}
