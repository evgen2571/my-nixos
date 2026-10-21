{ root }:
let
  catalog = import (root + "/lib/module-catalog.nix") { inherit root; };
  relative =
    path: builtins.substring (builtins.stringLength (toString root) + 1) (-1) (toString path);
in
{
  modules = map (entry: entry // { path = relative entry.path; }) catalog.modules;
  profiles = builtins.mapAttrs (_: profile: {
    system = map relative profile.systemModules;
    home = map relative profile.homeModules;
  }) catalog.profiles;
}
