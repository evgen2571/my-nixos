{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.my.system.files.thunar;
in
{
  options.my.system.files.thunar.enable = lib.mkEnableOption "Thunar file manager";

  config = lib.mkIf cfg.enable ({
    programs.thunar.enable = true;
    services.gvfs.enable = true;
    services.tumbler.enable = true;

    environment.systemPackages = with pkgs; [
      adw-gtk3
      nwg-look
    ];
  });
}
