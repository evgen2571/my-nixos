{ lib, disko }:
let
  layout = import ../../provisioning/layout.nix;
  make =
    host:
    layout {
      inherit lib host;
      device = "/dev/disk/by-id/test-system";
    };
  parts =
    host:
    (lib.evalModules {
      modules = [
        { options.disko.devices = lib.mkOption { type = disko.lib.toplevel; }; }
        { disko.devices = (make host).disko.devices; }
      ];
    }).config.disko.devices.disk.system.content.partitions;
  rejects = args: !(builtins.tryEval (builtins.deepSeq (layout args) true)).success;
in
assert rejects {
  inherit lib;
  host = "pc";
};
assert rejects {
  inherit lib;
  device = "/dev/vda";
};
assert rejects {
  inherit lib;
  host = "unknown";
  device = "/dev/vda";
};
assert rejects {
  inherit lib;
  host = "pc";
  device = "";
};
assert lib.all (host: builtins.attrNames (make host).disko.devices.disk == [ "system" ]) [
  "pc"
  "laptop"
  "server"
];
assert lib.all (host: (parts host).root.content.format == "ext4") [
  "pc"
  "laptop"
  "server"
];
assert (parts "pc").ESP.content.mountpoint == "/efi";
assert (parts "pc").boot.type == "EA00";
assert (parts "pc").boot.content.mountpoint == "/boot";
assert (parts "pc").boot.size == "2G";
assert (parts "laptop").ESP.size == "512M";
assert (parts "laptop").ESP.content.mountpoint == "/boot";
assert (parts "server").ESP.size == "1G";
assert (parts "server").swap.size == "8G";
assert (parts "server").swap.content.type == "swap";
assert (parts "pc").root.device == "/dev/disk/by-id/test-system-part3";
assert (parts "laptop").root.device == "/dev/disk/by-id/test-system-part2";
assert (parts "server").swap.device == "/dev/disk/by-id/test-system-part2";
assert lib.all (host: (parts host).ESP.device == "/dev/disk/by-id/test-system-part1") [
  "pc"
  "laptop"
  "server"
];
assert
  (make "pc").swapDevices == [
    {
      device = "/swapfile";
      size = 16384;
    }
  ];
assert (make "laptop").swapDevices == (make "pc").swapDevices;
assert !(make "server" ? swapDevices);
assert (make "pc").boot.loader.efi.efiSysMountPoint == "/efi";
assert (make "pc").boot.loader.systemd-boot.xbootldrMountPoint == "/boot";
assert (make "laptop").boot.loader.efi.efiSysMountPoint == "/boot";
true
