# nix eval --impure .#nixosConfigurations.nixos-pc --apply 'import ./lib/test-pc-disko.nix'
{ config, ... }:
let
  disk = config.disko.devices.disk.nvme;
  partitions = disk.content.partitions;
  subvolumes = partitions.root.content.subvolumes;
  mounts = {
    "@root" = "/";
    "@home" = "/home";
    "@nix" = "/nix";
    "@games" = "/games";
    "@var-lib" = "/var/lib";
    "@snapshots" = "/.snapshots";
  };
in
assert builtins.attrNames config.disko.devices.disk == [ "nvme" ];
assert
  builtins.attrNames partitions == [
    "ESP"
    "root"
  ];
assert partitions.ESP.size == "2G" && partitions.ESP.type == "EF00";
assert partitions.ESP.content.format == "vfat";
assert partitions.root.size == "100%";
assert builtins.attrNames subvolumes == builtins.attrNames mounts;
assert builtins.all (
  name:
  let
    mount = mounts.${name};
    fs = config.fileSystems.${mount};
  in
  subvolumes.${name}.mountpoint == mount
  && fs.fsType == "btrfs"
  && fs.device == partitions.root.content.device
  && builtins.all (option: builtins.elem option fs.options) [
    "subvol=${name}"
    "compress=zstd"
    "noatime"
  ]
) (builtins.attrNames mounts);
assert config.fileSystems."/var/lib".neededForBoot;
assert config.fileSystems."/boot".device == partitions.ESP.content.device;
assert config.fileSystems."/boot".fsType == "vfat";
assert !(config.fileSystems ? "/efi");
assert config.boot.loader.efi.efiSysMountPoint == "/boot";
assert config.boot.loader.systemd-boot.enable;
assert config.boot.loader.systemd-boot.xbootldrMountPoint == null;
assert config.swapDevices == [ ] && config.zramSwap.enable;
assert config.services.fstrim.enable && config.services.fstrim.interval == "weekly";
assert config.services.btrfs.autoScrub.enable;
assert config.services.btrfs.autoScrub.fileSystems == [ "/" ];
assert config.services.btrfs.autoScrub.interval == "monthly";
assert config.system.stateVersion == "25.11";
assert config.system.build.toplevel.drvPath != "";
true
