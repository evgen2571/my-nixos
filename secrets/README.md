# Encrypted secrets

This directory holds only sops-encrypted files. Do not commit plaintext secret
values, age identities, or SSH private keys.

Files are intentionally absent until the actual recipients are available:

```text
secrets/common.yaml
secrets/hosts/pc.yaml
secrets/hosts/laptop.yaml
secrets/hosts/server.yaml
```

Each host file is encrypted to its host recipient and the personal/admin
recipient. `common.yaml` is encrypted to the admin recipient and every host
that consumes a value from it. A host must not be added to a file only because
it exists in this repository.

See [the repository sops guide](../docs/sops.md) before creating these files.
