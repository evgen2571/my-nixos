{ lib }:
let
  paths = import ../../lib/config-paths.nix {
    root = ../..;
    inherit lib;
  };
  adapters = paths.dotfileAdapters;
  niri = adapters.niri { };
  discovered = adapters.niri { configDir = ./niri; };

in
assert
  builtins.attrNames discovered == [
    "niri/sub/rules/new.kdl"
    "niri/sub/workspaces.kdl"
  ];
assert !(niri ? "niri/noctalia.kdl");
assert !(niri ? "niri/noctalia-dropdown.kdl");
assert !(niri ? "niri/sub/workspaces-pc.kdl");
assert !(niri ? "niri/sub/workspaces-laptop.kdl");
assert discovered."niri/sub/rules/new.kdl".source == ./niri/sub/rules/new.kdl;
assert lib.all
  (
    profile:
    let
      files = adapters.niri { workspaceProfile = profile; };
    in
    builtins.attrNames files == builtins.attrNames niri
    &&
      files."niri/sub/workspaces.kdl".source == paths.wm.niriConfigDir + "/sub/workspaces-${profile}.kdl"
  )
  [
    "pc"
    "laptop"
  ];
assert niri."niri/sub/workspaces.kdl".source == paths.wm.niriConfigDir + "/sub/workspaces.kdl";
assert (adapters.fish { })."fish/conf.d".recursive;
assert (adapters.fish { })."fish/functions".recursive;
assert (adapters.kitty { })."kitty/kitty.conf".source == paths.dev.kitty.configFile;
assert lib.hasSuffix "font_size        13.0\n"
  (adapters.kitty { fontSize = "13.0"; })."kitty/kitty.conf".text;
assert (adapters.starship { })."starship.toml".source == paths.dev.starship.configFile;
assert (adapters.hyprland { })."hypr/sub".recursive;
assert (adapters.hyprland { })."hypr/sub".source == paths.wm.hyprlandConfigDir + "/sub";
assert
  builtins.attrNames (adapters.kdeplasma { }) == [
    "kcminputrc"
    "kwinrc"
    "kxkbrc"
  ];
true
