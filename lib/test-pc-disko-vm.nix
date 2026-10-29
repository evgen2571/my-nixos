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
  testMode = "module";
  testBoot = true;
  extraInstallerConfig.environment.systemPackages = [ pkgs.mkpasswd ];
  extraSystemConfig = { config, lib, ... }: {
    imports = [
      inputs.home-manager.nixosModules.home-manager
      inputs.sops-nix.nixosModules.sops
      ../modules/core/primary-user.nixos.nix
      ../hosts/pc/game-storage.nix
      ../hosts/pc/recovery.nix
    ];
    # Home Manager needs a writable store; keep all writes in the disposable VM.
    fileSystems."/nix/.ro-store" = {
      device = "nix-store";
      fsType = "9p";
      neededForBoot = true;
      options = [
        "trans=virtio"
        "version=9p2000.L"
        "cache=loose"
        "ro"
      ];
    };
    fileSystems."/nix/store" = lib.mkOverride 40 {
      neededForBoot = true;
      overlay = {
        lowerdir = [ "/nix/.ro-store" ];
        upperdir = "/nix/.rw-store/upper";
        workdir = "/nix/.rw-store/work";
      };
    };
    my.primaryUser = {
      enable = true;
      name = "player";
      extraGroups = [ "wheel" ];
      home.settings = {
        imports = [
          ../hosts/pc/home.nix
          inputs.wallpapers.homeManagerModules.default
        ];
        wallpapers.enable = true;
        wallpapers.directory = "/home/player/pictures/wallpapers";
        home.stateVersion = "25.11";
      };
    };
    home-manager = {
      verbose = true;
      useUserPackages = true;
      useGlobalPkgs = true;
      sharedModules = [ ../modules/dev/git.home.nix ];
    };
    environment.systemPackages = [ pkgs.pamtester ];
    users.mutableUsers = false;
    users.users.player.hashedPassword = "!";
    # An upstream encrypted fixture, deliberately without its decryption identity.
    sops.age.keyFile = "/var/lib/sops-nix/unavailable-test-key.txt";
    sops.age.sshKeyPaths = [ ];
    sops.gnupg.sshKeyPaths = [ ];
    sops.secrets.vm-password = {
      sopsFile = inputs.sops-nix + "/pkgs/sops-install-secrets/test-assets/secrets.yaml";
      key = "test_key";
      neededForUsers = true;
    };
    # Disko's harness registers the closure in the installer DB, not the target DB.
    systemd.services.nix-daemon.preStart = ''
      ${config.nix.package}/bin/nix-store --load-db < ${
        pkgs.closureInfo {
          rootPaths = [ config.home-manager.users.player.home.activationPackage ];
        }
      }/registration
    '';
    system.stateVersion = "25.11";
  };
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
    machine.succeed("mount -o subvol=@root /dev/vdb2 /mnt")
    for subvolume, mount in [("@home", "home"), ("@nix", "nix"), ("@games", "games"), ("@var-lib", "var/lib"), ("@snapshots", ".snapshots")]:
        machine.succeed(f"mkdir -p /mnt/{mount}; mount -o subvol={subvolume} /dev/vdb2 /mnt/{mount}")
    machine.succeed("mkdir /mnt/boot; mount /dev/vdb1 /mnt/boot")
    machine.succeed("mkdir -p /mnt/var/lib/nixos; umask 077; head -c 32 /dev/urandom | base64 > /mnt/var/lib/nixos/test-password; mkpasswd -m yescrypt -s < /mnt/var/lib/nixos/test-password > /mnt/var/lib/nixos/recovery-password")
  '';
  extraTestScript = ''
    try:
        machine.wait_for_unit("home-manager-player.service")
    except Exception:
        print(machine.succeed("journalctl -b -u home-manager-player.service --no-pager"))
        raise
    machine.succeed("test -d /sys/firmware/efi")
    machine.succeed("findmnt -n -t btrfs --mountpoint /var/lib")
    machine.succeed("test -f /home/keep-home; test -f /games/keep-games; test -f /var/lib/keep-state")
    machine.succeed("test ! -e /old-root; test ! -e /run/secrets-for-users/vm-password")
    machine.succeed("test \"$(getent shadow root | cut -d: -f2)\" = \"$(cat /var/lib/nixos/recovery-password)\"")
    machine.succeed("pamtester login root authenticate < /var/lib/nixos/test-password")
    machine.fail("echo wrong-test-password | pamtester login root authenticate")
    machine.succeed("test -d /home/player/dev; test ! -L /home/player/dev")
    machine.fail("btrfs subvolume show /home/player/dev")
    machine.succeed("test ! -e /home/player/Documents; test ! -e /home/player/Downloads")
    for path, target in [("games", "/games"), (".local/share/Steam/steamapps", "/games/steam/steamapps"), (".local/share/PrismLauncher/instances", "/games/minecraft/instances")]:
        machine.succeed(f"test $(readlink -f /home/player/{path}) = {target}")
        machine.succeed(f"test $(stat -c %U {target}) = player" if path != "games" else "true")
    machine.succeed("systemctl restart home-manager-player.service")
    machine.succeed("touch /games/steam/steamapps/keep; systemctl restart game-storage; test -f /games/steam/steamapps/keep")
    machine.succeed("rmdir /games/minecraft/instances /games/minecraft; ln -s /home/player /games/minecraft")
    machine.fail("systemctl restart game-storage")
    machine.succeed("test -L /games/minecraft; test ! -e /home/player/instances; unlink /games/minecraft; systemctl start game-storage")
    machine.succeed("systemctl stop home-manager-player.service game-storage.service; umount /games")
    machine.succeed("systemd-tmpfiles --create")
    machine.succeed("test ! -e /games/steam; test ! -e /games/minecraft")
  '';
}
