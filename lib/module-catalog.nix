{
  root,
  legacyEntries ? builtins.fromJSON (builtins.readFile ./module-compatibility.json),
}:

let
  inherit (builtins)
    concatLists
    elem
    filter
    map
    ;

  discovery = import ./module-discovery.nix { inherit root; };

  # Keep system modules and Home Manager modules in their own profiles.
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

  # Typed rules own availability; colocated entries need not share profiles.
  typedRoots = [
    {
      relPath = "/modules/ai";
      system = [ ];
      home = [ "desktop" ];
    }
    {
      relPath = "/modules/apps";
      system = [ "desktop" ];
      home = [ "desktop" ];
    }
    {
      relPath = "/modules/desktop";
      system = [ "desktop" ];
      home = [ "desktop" ];
    }
    {
      relPath = "/modules/dev";
      system = [ "desktop" ];
      home = [
        "desktop"
        "server"
      ];
    }
    {
      relPath = "/modules/files";
      system = [ "desktop" ];
      home = [ "desktop" ];
    }
    {
      relPath = "/modules/services";
      system = [
        "desktop"
        "server"
      ];
      home = [ ];
    }
  ]
  ++ map (rule: {
    inherit (rule) relPath;
    system = if rule.scope == "system" then rule.profiles else [ ];
    home = if rule.scope == "home" then rule.profiles else [ ];
  }) profileRoots;

  relative =
    path: builtins.substring (builtins.stringLength (toString root) + 1) (-1) (toString path);
  fail = message: throw "module catalog: ${message}";
  unique =
    values:
    builtins.length values == builtins.length (
      builtins.attrNames (
        builtins.listToAttrs (
          map (value: {
            name = value;
            value = true;
          }) values
        )
      )
    );

  typed = concatLists (
    map (
      rule:
      map (
        entry:
        if rule.${entry.scope} == [ ] then
          fail "wrong scope ${entry.scope} for ${relative entry.path} under ${rule.relPath}"
        else
          entry
          // {
            inherit (rule) relPath;
            profiles = rule.${entry.scope};
          }
      ) (discovery.typedUnder rule.relPath)
    ) typedRoots
  );
  typedPaths = map (entry: relative entry.path) typed;
  legacyPaths = concatLists (
    map (rule: map relative (discovery.modulesUnder rule.relPath)) profileRoots
  );

  registrationsValid =
    if
      !(unique (map (entry: entry.path) legacyEntries))
      || !(unique (map (entry: entry.target) legacyEntries))
    then
      fail "duplicate legacy or target registration in module-compatibility.json"
    else
      builtins.all (
        entry:
        if
          !(elem entry.scope [
            "system"
            "home"
          ])
        then
          fail "invalid scope ${entry.scope} for ${entry.path}"
        else if
          entry.profiles == [ ]
          || !(builtins.all (
            name:
            elem name [
              "desktop"
              "server"
            ]
          ) entry.profiles)
        then
          fail "invalid profiles for ${entry.path}"
        else
          true
      ) legacyEntries;

  compatible = map (
    entry:
    let
      old = elem entry.path legacyPaths;
      new = elem entry.target typedPaths;
      target = filter (item: relative item.path == entry.target) typed;
      owner = filter (rule: rule.relPath == entry.relPath) profileRoots;
    in
    if old && new then
      fail "duplicate registration: ${entry.path} and ${entry.target}; remove the legacy entry when migrating"
    else if !old && !new then
      fail "missing expected entry: ${entry.path} or ${entry.target}"
    else if
      owner == [ ]
      || (builtins.head owner).scope != entry.scope
      || (builtins.head owner).profiles != entry.profiles
    then
      fail "invalid legacy scope/profile assignment for ${entry.path}"
    else if
      new
      && (
        (builtins.head target).scope != entry.scope || (builtins.head target).profiles != entry.profiles
      )
    then
      fail "typed scope/profile rules disagree with compatibility registration for ${entry.target}"
    else
      {
        path = root + "/${if new then entry.target else entry.path}";
        inherit (entry) scope profiles;
        relPath = if new then (builtins.head target).relPath else entry.relPath;
      }
  ) legacyEntries;

  ordinary = filter (
    entry: !(elem (relative entry.path) (map (item: item.target) legacyEntries))
  ) typed;
  modules =
    assert registrationsValid;
    if !(unique typedPaths) then
      fail "duplicate typed entry registered by overlapping catalog roots"
    else
      compatible ++ ordinary;

  pathsFor =
    profile: scope:
    map (module: module.path) (
      filter (module: module.scope == scope && elem profile module.profiles) modules
    );
  profile = name: {
    systemModules = pathsFor name "system";
    homeModules = pathsFor name "home";
  };
in
{
  inherit modules profileRoots;
  profiles = {
    desktop = profile "desktop";
    server = profile "server";
  };
}
