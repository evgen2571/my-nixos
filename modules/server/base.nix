{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.server.base;
in
{
  options.my.server.base.enable = lib.mkEnableOption "base server module";

  config = lib.mkIf cfg.enable {
    services.fstrim.enable = true;

    services.smartd = {
      enable = true;
      autodetect = true;
    };

    services.journald.extraConfig = ''
      SystemMaxUse=1G
      MaxRetentionSec=30day
    '';

    environment.systemPackages = with pkgs; [
      curl
      git
      htop
      jq
      lsof
      ncdu
      pciutils
      ripgrep
      rsync
      smartmontools
      tmux
      tree
      unzip
      usbutils
      vim
      wget
    ];

    security.sudo.wheelNeedsPassword = true;
  };
}
