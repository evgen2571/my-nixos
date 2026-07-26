# This file is an intentional placeholder.
#
# On the target server, generate the hardware configuration with:
#
#   sudo nixos-generate-config --show-hardware-config
#
# Replace this file with the generated Nix module.
#
# The generated file contains detected hardware, kernel-module, filesystem,
# swap, and platform declarations specific to the target server.
#
# Do not copy hardware configuration from the PC or laptop.
#
# Bootloader policy is configured separately in:
#
#   modules/system-core/server.nix
#
# The current server bootloader policy assumes UEFI firmware and systemd-boot.
# Verify that this is appropriate for the target server before activation.
{ lib, ... }:

{
  assertions = [
    {
      assertion = false;
      message = ''
        hosts/server/hardware-configuration.nix is still a placeholder.
        Generate the real file on the target server with:

          sudo nixos-generate-config --show-hardware-config > hosts/server/hardware-configuration.nix

        Then rerun:

          nix build .#nixosConfigurations.nixos-server.config.system.build.toplevel
      '';
    }
  ];
}
