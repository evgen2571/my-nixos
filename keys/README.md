# SSH Public Keys

This directory contains only SSH public keys (`.pub`). Private keys never belong
in Git. Maintainer login-key associations are supplied only by the optional private input.

## Layout

```text
keys/
├── README.md
├── users/
│   └── <user>/
│       ├── pc.pub
│       └── laptop.pub
└── hosts/
    └── ...
```

Use the directories by **what the key authenticates**, not by where the private
key happens to live:

- `keys/users/<user>/` — user-login public keys used in
  `users.users.<name>.openssh.authorizedKeys`. A key generated on a PC or laptop
  for logging in as a user belongs here.
- `keys/hosts/` — reserved for SSH **host identity/trust** public keys if the
  repository later manages them. Do not put normal login keys here.

Keeping user keys namespaced by account also scales better than placing every
`.pub` file directly in `keys/`.

## Policy

- **Only public keys** may be stored here.
- **Never commit** private keys, age keys, or any secret material.
- Key-line comments (for example `example-device`) may reveal a device name or
  email address, so keep comments descriptive but appropriate.

## Adding a login key

1. Copy the `.pub` file into `keys/users/<user>/` with a descriptive filename.
2. Add the relative path to `authorizedKeyFiles` in the target host's
   `configuration.nix`:

   ```nix
   my.primaryUser.authorizedKeyFiles = [
     ../../keys/users/your-user/device.pub
   ];
   ```

3. Run formatting and a build:

   ```bash
   nix fmt hosts/my-host/configuration.nix
   nix build --no-link .#nixosConfigurations.my-host.config.system.build.toplevel
   ```

4. Keep the current SSH session open.
5. Test a new session with the added key.
6. Only close the original session after confirming access.

## Revoking a login key

1. Remove the key path from `authorizedKeyFiles` in the host configuration.
2. Rebuild safely (dry-build first).
3. Confirm another active key still authenticates.
4. Verify the revoked key no longer works.

## Testing safely

Always keep an existing SSH session open while testing a new key. If the new
key fails, the existing session remains available for recovery.
