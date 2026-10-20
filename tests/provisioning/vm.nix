{
  pkgs,
  disko,
  host,
}:
let
  inherit (pkgs) lib;
  layout = import ../../provisioning/layout.nix {
    inherit lib host;
    device = "/dev/vda";
  };
  pc = host == "pc";
  server = host == "server";
in
disko.lib.testLib.makeDiskoTest {
  inherit pkgs;
  name = "provision-${host}";
  disko-config = layout;
  extraInstallerConfig = {
    virtualisation.emptyDiskImages = lib.mkForce [
      14336
      64
    ];
    # Keep a previously provisioned disk connected with colliding partition labels.
    services.udev.extraRules = ''
      SUBSYSTEM=="block", KERNEL=="vdc1", ENV{ID_PART_ENTRY_NAME}=="disk-system-root", OPTIONS+="link_priority=100"
    '';
    boot.postBootCommands = ''
      ${pkgs.gptfdisk}/bin/sgdisk --clear --new=1:0:0 --change-name=1:disk-system-root /dev/vdc
      udevadm trigger --subsystem-match=block
      udevadm settle
      ${pkgs.e2fsprogs}/bin/mkfs.ext4 /dev/vdc1
      sha256sum /dev/vdc > /run/preserved-disk.sha256
    '';
  };
  # Disko's test helper rewrites boot options when remapping virtual disks.
  extraSystemConfig = {
    inherit (layout) boot;
  }
  // lib.optionalAttrs (!server) {
    # Exercise swapfile creation without allocating 16 GiB in each disposable VM.
    swapDevices = lib.mkForce [
      {
        device = "/swapfile";
        size = 64;
      }
    ];
  };
  postDisko = ''
    machine.succeed("sha256sum --check /run/preserved-disk.sha256")
    machine.succeed("test $(readlink -f /dev/disk/by-partlabel/disk-system-root) = /dev/vdc1")
    machine.succeed("test $(findmnt -nro SOURCE /mnt) = /dev/vdb${if pc || server then "3" else "2"}")
    machine.succeed("nixos-generate-config --root /mnt --show-hardware-config > /tmp/generated.nix")
    generated = machine.succeed("cat /tmp/generated.nix")
    assert 'fsType = "ext4"' in generated
    assert 'fileSystems."/boot"' in generated
    ${lib.optionalString pc ''assert 'fileSystems."/efi"' in generated''}
    ${lib.optionalString server ''assert "swapDevices" in generated and "/dev/disk/by-uuid/" in generated''}
  '';
  extraTestScript = ''
    import json
    machine.succeed("test -d /sys/firmware/efi; mountpoint /boot; mountpoint /")
    machine.succeed("test -s ${if pc then "/efi" else "/boot"}/EFI/BOOT/BOOTX64.EFI")
    machine.succeed("ls /boot/loader/entries/nixos*.conf")
    parts = json.loads(machine.succeed("lsblk --json -o NAME,FSTYPE,PARTTYPE /dev/vda"))["blockdevices"][0]["children"]
    assert len(parts) == ${if pc || server then "3" else "2"}, parts
    assert parts[0]["fstype"] == "vfat", parts
    assert parts[-1]["fstype"] == "ext4", parts
    ${
      if pc then
        ''
          machine.succeed("mountpoint /efi")
          assert parts[1]["parttype"] == "bc13c2ff-59e6-4262-a352-b275fd6f7172", parts
        ''
      else if server then
        ''
          assert parts[1]["fstype"] == "swap", parts
          machine.succeed("swapon --show=NAME --noheadings | grep /dev/vda2")
        ''
      else
        ""
    }
    ${lib.optionalString (!server) ''
      machine.succeed("test $(stat -c %s /swapfile) = 67108864")
      machine.succeed("swapon --show=NAME --noheadings | grep /swapfile")
    ''}
    # Explicitly stop the booted VM created by disko's test helper.
    machine.shutdown()
  '';
}
