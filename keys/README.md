# SSH Public Keys

This directory contains only SSH public key files (`.pub`) for declarative
authorized-keys management via `users.users.<name>.openssh.authorizedKeys.keyFiles`.

## Policy

- **Only public keys** may be stored here.
- **Never commit** private keys, age keys, or any secret material.
- Key-line comments (e.g. `evgen2571-pc`) may reveal a device name or email
  address — choose descriptive but appropriate names.

## Adding a key

1. Copy the `.pub` file into this directory with a descriptive filename.
2. Add the relative path to `authorizedKeyFiles` in the target host's
   `configuration.nix`:

   ```nix
   my.primaryUser.authorizedKeyFiles = [
     ../../keys/your-name.pub
   ];
   ```

3. Run formatting and a build:

   ```bash
   nix fmt
   nix build .#nixosConfigurations.nixos-server.config.system.build.toplevel
   ```

4. Keep the current SSH session open.
5. Test a new session with the added key.
6. Only close the original session after confirming access.

## Revoking a key

1. Remove the key path from `authorizedKeyFiles` in the host configuration.
2. Rebuild safely (dry-build first).
3. Confirm another active key still authenticates.
4. Verify the revoked key no longer works.

## Testing safely

Always keep an existing SSH session open while testing a new key. If the new
key fails, the existing session remains available for recovery.
