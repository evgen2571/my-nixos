{ root }:

let
  inherit (builtins)
    concatLists
    elem
    filter
    map
    ;

  discovery = import ./module-discovery.nix { inherit root; };

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
    {
      relPath = "/modules/hardware";
      system = [ "desktop" ];
      home = [ ];
    }
    {
      relPath = "/modules/server";
      system = [ "server" ];
      home = [ ];
    }
  ];

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
  # Preserve established import order; new features follow in discovery order.
  order = builtins.fromJSON (builtins.readFile ./module-order.json);
  ordered = concatLists (map (path: filter (entry: relative entry.path == path) typed) order);
  ordinary = filter (entry: !(elem (relative entry.path) order)) typed;
  modules =
    if !(unique order) then fail "duplicate path in module-order.json" else ordered ++ ordinary;

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
  inherit modules;
  profiles = {
    desktop = profile "desktop";
    server = profile "server";
  };
}
