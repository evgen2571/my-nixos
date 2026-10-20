# Installation-only module; never imported by the existing host configurations.
{
  lib,
  host ? null,
  device ? null,
  ...
}:
assert lib.assertMsg (builtins.elem host [
  "pc"
  "laptop"
  "server"
]) "Select pc, laptop or server explicitly";
assert lib.assertMsg (
  builtins.isString device && builtins.match "/dev/[a-zA-Z0-9._/+:=-]+" device != null
) "Select an explicit /dev/ disk path";
let
  pc = host == "pc";
  server = host == "server";
  # Bind every operation to the selected disk, even with duplicate GPT labels.
  partition =
    definition:
    { config, ... }:
    let
      disk = config.content._parent.device;
      separator =
        if lib.hasPrefix "/dev/disk/" disk then
          "-part"
        else if builtins.match ".*[0-9]" disk != null then
          "p"
        else
          "";
    in
    definition // { device = "${disk}${separator}${toString config._index}"; };
  fat = mountpoint: mask: {
    type = "filesystem";
    format = "vfat";
    inherit mountpoint;
    mountOptions = [
      "fmask=${mask}"
      "dmask=${mask}"
    ];
  };
in
{
  disko.devices.disk.system = {
    type = "disk";
    inherit device;
    content = {
      type = "gpt";
      partitions = {
        ESP = partition {
          priority = 1;
          type = "EF00";
          size = if server then "1G" else "512M";
          content = fat (if pc then "/efi" else "/boot") (if pc then "0077" else "0022");
        };
        root = partition {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
      }
      // lib.optionalAttrs pc {
        boot = partition {
          priority = 2;
          type = "EA00";
          size = "2G";
          content = fat "/boot" "0077";
        };
      }
      // lib.optionalAttrs server {
        swap = partition {
          priority = 2;
          size = "8G";
          content.type = "swap";
        };
      };
    };
  };

  boot.loader = {
    systemd-boot = {
      enable = true;
      xbootldrMountPoint = if pc then "/boot" else null;
    };
    efi.efiSysMountPoint = if pc then "/efi" else "/boot";
  };
}
// lib.optionalAttrs (!server) {
  # NixOS creates the swapfile during installation/boot; disko only formats partitions.
  swapDevices = [
    {
      device = "/swapfile";
      size = 16384;
    }
  ];
}
