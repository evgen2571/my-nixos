# nix build --impure --expr 'import ./lib/test-pc-disko-vm.nix {}' --no-link -L
{
  inputs ? (builtins.getFlake (toString ../.)).inputs,
}:
let
  pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
in
inputs.disko.lib.testLib.makeDiskoTest {
  inherit pkgs;
  name = "pc-layout";
  disko-config = import ../hosts/pc/disko.nix { inherit (pkgs) lib; };
  testMode = "direct";
  testBoot = false;
  postDisko = ''
    machine.succeed("test $(blockdev --getsize64 /dev/vdb1) -eq 2147483648")
    machine.succeed("test $(blkid -s TYPE -o value /dev/vdb1) = vfat")
    machine.succeed("test \"$(blkid -p -s VERSION -o value /dev/vdb1)\" = FAT32")
    machine.succeed("test $(blkid -s TYPE -o value /dev/vdb2) = btrfs")
    for mount in ["/", "/home", "/nix", "/games", "/var/lib", "/.snapshots"]:
        target = "/mnt" + mount.rstrip("/")
        machine.succeed(f"findmnt -n -t btrfs --mountpoint {target}")
        machine.succeed(f"findmnt -n -o OPTIONS --mountpoint {target} | grep -E 'compress=zstd(:[0-9]+)?(,|$)'")
        machine.succeed(f"findmnt -n -o OPTIONS --mountpoint {target} | grep -w noatime")
    machine.succeed("findmnt -n -t vfat --mountpoint /mnt/boot")
    machine.succeed("test -z \"$(swapon --noheadings --show)\"")
    machine.succeed("touch /mnt/home/keep-home /mnt/games/keep-games /mnt/var/lib/keep-state")
    machine.succeed("touch /mnt/old-root")
    machine.succeed("umount -R /mnt")
    machine.succeed("mkdir /tmp/btrfs-top; mount -o subvolid=5 /dev/vdb2 /tmp/btrfs-top")
    machine.succeed("btrfs subvolume delete /tmp/btrfs-top/@root")
    machine.succeed("btrfs subvolume create /tmp/btrfs-top/@root")
    machine.succeed("test ! -e /tmp/btrfs-top/@root/old-root")
    machine.succeed("test -f /tmp/btrfs-top/@home/keep-home")
    machine.succeed("test -f /tmp/btrfs-top/@games/keep-games")
    machine.succeed("test -f /tmp/btrfs-top/@var-lib/keep-state")
    machine.succeed("umount /tmp/btrfs-top")
  '';
}
