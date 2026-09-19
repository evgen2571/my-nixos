# Encrypted secrets

This directory holds only SOPS-encrypted files. Encrypted YAML files and the
public age recipients used to encrypt them are intended to be committed. Never
commit plaintext secret values, decrypted working copies, or private age
identities.

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

Do not place arbitrary public configuration here. Usernames, hostnames, SSH
public keys, Git identity, and public age recipients remain normal repository
configuration.

See [the repository sops guide](../docs/sops.md) before creating these files.
