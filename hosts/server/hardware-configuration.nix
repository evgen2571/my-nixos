# This file must be replaced on the real server before the host can build.
#
# Generate it on the target machine with:
#
#   sudo nixos-generate-config --show-hardware-config > hosts/server/hardware-configuration.nix
#
# Review the generated output carefully before replacing this placeholder.
# The generated file will contain filesystem declarations, bootloader settings,
# CPU/memory/disk configuration specific to the server hardware.
#
# Do not copy hardware configuration from nixos-pc or nixos-laptop — the
# server likely has different disks, boot mode, and hardware topology.
#
# After replacing, run a non-activating build:
#
#   nix build .#nixosConfigurations.nixos-server.config.system.build.toplevel
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
