{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.user.files.dolphin;
in
{
  options.my.user.files.dolphin.enable = lib.mkEnableOption "Dolphin file manager";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      kdePackages.qtsvg
      kdePackages.kio
      kdePackages.kio-fuse
      kdePackages.kio-extras
      kdePackages.plasma-integration
      kdePackages.breeze
      kdePackages.dolphin
      kdePackages.ark
    ];
  };
}
