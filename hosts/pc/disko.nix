{ lib, ... }:

{
  disko.devices.disk.nvme = {
    type = "disk";
    # Set the verified whole-disk by-id path in the private PC module.
    device = lib.mkDefault "/dev/disk/by-id/REPLACE-ME-WD_BLACK_SN850X_1000GB";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "2G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            extraArgs = [
              "-F"
              "32"
            ];
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
        root = {
          size = "100%";
          content = {
            type = "btrfs";
            subvolumes =
              lib.mapAttrs
                (_: mountpoint: {
                  inherit mountpoint;
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                })
                {
                  "@root" = "/";
                  "@home" = "/home";
                  "@nix" = "/nix";
                  "@games" = "/games";
                  "@var-lib" = "/var/lib";
                  "@snapshots" = "/.snapshots";
                };
          };
        };
      };
    };
  };
}
