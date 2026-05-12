# This file must be replaced on the real server before the host can build.
# Generate it on the target machine with:
#
#   sudo nixos-generate-config --show-hardware-config > hosts/server/hardware-configuration.nix
#
# Keep only the hardware settings generated for that machine/VM.
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

          sudo nixos-rebuild dry-build --flake .#nixos-server
      '';
    }
  ];
}
