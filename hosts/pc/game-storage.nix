{
  config,
  lib,
  pkgs,
  ...
}:
let
  user = config.my.primaryUser.name;
  group = config.users.users.${user}.group;
  paths = [
    "/games/steam"
    "/games/steam/steamapps"
    "/games/minecraft"
    "/games/minecraft/instances"
  ]
  ++ lib.optionals config.my.system.apps.hydraLauncher.enable [
    "/games/hydra"
    "/games/hydra/downloads"
    "/games/hydra/installed"
    "/games/hydra/prefixes"
  ];
  # Keep these rules out of global tmpfiles runs: they require the games mount.
  directories = pkgs.writeText "game-storage.conf" (
    lib.concatMapStringsSep "\n" (path: "d ${path} 0755 ${user} ${group} - -") paths
  );
in
{
  systemd.services.game-storage = {
    description = "Prepare game directories on the mounted games subvolume";
    wantedBy = [ "multi-user.target" ];
    unitConfig.RequiresMountsFor = [ "/games" ];
    before = [ "home-manager-${user}.service" ];
    unitConfig.ConditionPathIsMountPoint = "/games";
    preStart = ''
      for path in ${lib.escapeShellArgs paths}; do
        if [ -L "$path" ] || { [ -e "$path" ] && [ ! -d "$path" ]; }; then
          echo "Refusing conflicting game directory: $path" >&2
          exit 1
        fi
      done
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.systemd}/bin/systemd-tmpfiles --create ${directories}";
    };
  };
  systemd.services."home-manager-${user}".requires = [ "game-storage.service" ];
}
