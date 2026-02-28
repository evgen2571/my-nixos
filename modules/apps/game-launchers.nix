{
  lib,
  pkgs,
  inputs,
  ...
}: let
  pkgsUnstable = import inputs.nixpkgs-unstable {
    inherit (pkgs) system;
    config.allowUnfree = true;
  };

  animeGameLauncher = lib.attrByPath [ "anime-game-launcher" ] null pkgsUnstable;
  sleepyLauncher = lib.attrByPath [ "sleepy-launcher" ] null pkgsUnstable;
in {
  home.packages = builtins.filter (pkg: pkg != null) [
    animeGameLauncher
    sleepyLauncher
  ];

  warnings =
    lib.optional (animeGameLauncher == null)
    "Package 'anime-game-launcher' was not found in nixpkgs-unstable; skipping install."
    ++ lib.optional (sleepyLauncher == null)
    "Package 'sleepy-launcher' was not found in nixpkgs-unstable; skipping install.";
}
