{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.my.system.services.virtualization;
in
{
  options.my.system.services.virtualization.enable =
    lib.mkEnableOption "Libvirt virtualization tooling";

  config = lib.mkIf cfg.enable {
    virtualisation.libvirtd = {
      enable = true;

      qemu = {
        swtpm.enable = true;
      };

      qemu.vhostUserPackages = with pkgs; [ virtiofsd ];
    };

    programs.virt-manager.enable = true;

    environment.systemPackages = with pkgs; [
      virtiofsd
    ];
  };
}
