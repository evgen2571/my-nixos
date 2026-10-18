# Add a standalone host

1. Copy this directory into `hosts/<name>/` in my-nixos. Generate
   `hardware-configuration.nix` for the target disks/hardware (for example with
   `nixos-generate-config --root /mnt` from installation media). Do not reuse a
   maintainer host's UUIDs. Review mounts, swap, firmware/bootloader, CPU/graphics
   firmware, network interface/DHCP or NetworkManager, timezone and disk encryption.
2. Set the hostname and primary user. Keep system/Home Manager state versions
   explicit and appropriate to the initial installation. Supply your SSH **public**
   key and an explicit firewall rule reaching the configured SSH port/interface.
   Passwords and root SSH stay locked. Test reachability from your console before
   relying on remote access. For key-only administration, explicitly choose a sudo
   policy (e.g. `security.sudo.wheelNeedsPassword = false` for your trusted wheel
   user), or provision a console password privately. No password/hash belongs in Git.
3. Register the host in `flake/hosts.nix` alongside the existing outputs:

   ```nix
   my-host = mkHost {
     host = "my-host";
     hostModule = ../hosts/my-host/configuration.nix;
     profile = moduleProfiles.server; # or desktop
     secretSource = "none";
   };
   ```

   Existing catalog discovery and Home Manager wiring apply. Select features in
   your copied `profile.nix`; this template enables no maintainer VPN or credentials.
4. Stage new files. Evaluate `.#nixosConfigurations.my-host.config.system.build.toplevel.drvPath`,
   then build `.#nixosConfigurations.my-host.config.system.build.toplevel` without
   activation. The template refuses evaluation until explicit SSH access is chosen.
5. Install only after reviewing target disks, console/recovery access and the
   resulting configuration. Installation is a separate destructive operator step;
   no disko/nixos-anywhere or private repository is needed. For controlled console
   provisioning instead of SSH, replace the SSH assertion with your own validated
   provisioning procedure; do not enable empty passwords or automatic login.

To adopt single-repository SOPS later, choose `secretSource = "local"`, add your
own tracked `.sops.yaml` and `secrets/hosts/my-host.yaml`, and declare consumers
using the supplied `secretFile` module argument. Preserve locked-password
behavior when absent. See [installation](../../docs/installation.md).
