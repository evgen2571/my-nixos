{
  config,
  inputs,
  lib,
  ...
}:

let
  cfg = config.my.user.apps.zenBrowser;
in
{
  imports = [
    inputs.zen-browser.homeModules.beta
  ];

  options.my.user.apps.zenBrowser = {
    enable = lib.mkEnableOption "Zen Browser";

    profilePath = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "abcdefgh.Default Profile";
      description = ''
        Existing Zen profile directory name (relative to ~/.config/zen).
        Set this only after checking about:profiles on this host. A null
        value leaves the current browser profile unmanaged.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    programs.zen-browser = {
      enable = true;

      profiles = lib.mkIf (cfg.profilePath != null) {
        default = (import ../../config/zen/profile.nix) // {
          path = cfg.profilePath;
          isDefault = true;
        };
      };
    };
  };
}
