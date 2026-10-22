# Local encrypted secrets

If you choose `secretSource = "local"`, put your own SOPS-encrypted `hosts/<host>.yaml` here and keep its recipient rule in the root `.sops.yaml`.

With `none` or `private`, these files aren't selected. Don't commit plaintext, age identities, password hashes, or decrypted editor backups.

See [secrets](../docs/secrets.md) for the three modes and [sops-nix](https://github.com/Mic92/sops-nix) for the encryption workflow.
