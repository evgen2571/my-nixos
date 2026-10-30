{
  config,
  lib,
  pkgs,
  ...
}:
let
  user = config.my.primaryUser.name;
  group = config.users.users.${user}.group;
  # Keep these rules out of global tmpfiles runs: they require the games mount.
  directories = pkgs.writeText "game-storage.conf" (
    lib.concatMapStringsSep "\n" (path: "d /games/${path} 0755 ${user} ${group} - -") [
      "steam"
      "steam/steamapps"
      "minecraft"
      "minecraft/instances"
    ]
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
      for path in /games/steam /games/steam/steamapps /games/minecraft /games/minecraft/instances; do
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
