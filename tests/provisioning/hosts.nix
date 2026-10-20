# Provisioning must not leak into the ordinary production host configurations.
{ configurations, lib }:
let
  pc = configurations.nixos-pc.config;
  laptop = configurations.nixos-lp.config;
  server = configurations.nixos-server.config;
  swapfile = c: map (s: { inherit (s) device size; }) c.swapDevices;
in
assert lib.all (host: !(host.config ? disko)) (builtins.attrValues configurations);
assert pc.fileSystems."/".device == "/dev/disk/by-uuid/3c70f92c-39a2-494f-829a-891073e92a15";
assert laptop.fileSystems."/".device == "/dev/disk/by-uuid/bad38231-8de2-41aa-a26c-861eba558f80";
assert server.fileSystems."/".device == "/dev/disk/by-uuid/876acc49-4141-488f-b931-c1a82bedcf76";
assert pc.boot.loader.efi.efiSysMountPoint == "/efi";
assert pc.boot.loader.systemd-boot.xbootldrMountPoint == "/boot";
assert laptop.boot.loader.efi.efiSysMountPoint == "/boot";
assert server.boot.loader.efi.efiSysMountPoint == "/boot";
assert
  swapfile pc == [
    {
      device = "/swapfile";
      size = 16384;
    }
  ];
assert swapfile laptop == swapfile pc;
assert
  map (s: s.device) server.swapDevices
  == [ "/dev/disk/by-uuid/8b032dc9-47ed-4cee-8635-ed6733b2a9e4" ];
assert pc.fileSystems."/home".device == "/dev/disk/by-uuid/f6960bc1-edf1-4409-b448-da1e8d3045fb";
assert
  pc.fileSystems."/home/${pc.my.primaryUser.name}/drive".device
  == "/dev/disk/by-uuid/36fdc2e6-80db-4ec6-91d4-b85282663a32";
assert
  laptop.fileSystems."/home/${laptop.my.primaryUser.name}/drive".device
  == "/dev/disk/by-uuid/d1038ac0-6fd0-4d1e-b6bf-c1dee40e8bec";
assert
  server.fileSystems."/srv/storage".device
  == "/dev/disk/by-uuid/ff9ba794-22fe-4906-a516-a3b438200259";
assert
  server.fileSystems."/srv/storage".options == [
    "defaults"
    "x-systemd.device-timeout=30s"
  ];
assert server.services.syncthing.dataDir == "/srv/appdata/syncthing";
true
