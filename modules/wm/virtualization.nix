{ config, pkgs, ... }:

{
  virtualisation.libvirtd = {
    enable = true;
    qemu.vhostUserPackages = with pkgs; [ virtiofsd ];
  };

  programs.virt-manager.enable = true;
  services.tailscale.enable = true;

  environment.systemPackages = with pkgs; [
    virtiofsd
  ];
}
