# Apply to the evaluated nixos-pc configuration, with its private input.
{ config, ... }:
let
  user = config.my.primaryUser.name;
  home = config.home-manager.users.${user};
  dir = home.home.homeDirectory;
  files = home.home.file;
  links = {
    games = "/games";
    "${home.xdg.dataHome}/Steam/steamapps" = "/games/steam/steamapps";
    "${home.xdg.dataHome}/PrismLauncher/instances" = "/games/minecraft/instances";
  };
in
assert home.xdg.userDirs.enable && home.xdg.userDirs.createDirectories;
assert home.xdg.userDirs.download == "${dir}/downloads";
assert home.xdg.userDirs.pictures == "${dir}/pictures";
assert home.xdg.userDirs.projects == "${dir}/dev";
assert builtins.all (name: home.xdg.userDirs.${name} == dir) [
  "desktop"
  "documents"
  "music"
  "publicShare"
  "templates"
  "videos"
];
assert builtins.all (
  name:
  toString files.${name}.source == toString (home.lib.file.mkOutOfStoreSymlink links.${name})
  && !files.${name}.force
) (builtins.attrNames links);
assert !(files ? dev);
assert files.wallpapers.target == "pictures/wallpapers";
assert files.wallpapers.recursive && !files.wallpapers.force;
assert home.programs.noctalia.settings.wallpaper.directory == "${dir}/${files.wallpapers.target}";
assert home.programs.noctalia.settings.theme.source == "wallpaper";
assert
  home.home.activation.checkPcHomeLayout.before == [
    "checkLinkTargets"
    "writeBoundary"
  ];
assert config.systemd.services.game-storage.unitConfig.RequiresMountsFor == [ "/games" ];
assert config.systemd.services.game-storage.unitConfig.ConditionPathIsMountPoint == "/games";
assert config.users.users.root.hashedPasswordFile == "/var/lib/nixos/recovery-password";
assert config.sops.secrets.user-password.neededForUsers;
assert home.home.stateVersion == "25.11";
true
