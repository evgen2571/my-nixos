{
  lib,
  configPaths,
  config,
  ...
}:
let
  cfg = config.my.user.desktop.niriConfig;
in
{
  options.my.user.desktop.niriConfig = {
    enable = lib.mkEnableOption "Niri user configuration";

    workspaceProfile = lib.mkOption {
      type = lib.types.enum [
        "default"
        "pc"
        "laptop"
      ];
      default = "default";
      description = "Named Niri workspace layout profile to map into ~/.config/niri/sub/workspaces.kdl.";
    };
  };

  config = lib.mkIf cfg.enable {
    xdg.configFile = configPaths.dotfileAdapters.niri {
      inherit (cfg) workspaceProfile;
    };
  };
}
