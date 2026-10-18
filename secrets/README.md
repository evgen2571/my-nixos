# Optional single-repository ciphertext

In explicit `local` mode, put your own SOPS-encrypted `hosts/<host>.yaml` here and
track matching `.sops.yaml` recipient policy at the repository root. No second
repository is required. `none` and `private` modes ignore these files.

Maintainer host/recovery ciphertext lives in the optional private input. Bootstrap
recovery documents remain admin-only and are not exported as host secret files.
Never commit plaintext, decrypted working copies or private identities. See the
[SOPS guide](../docs/operations/secrets.md) and [source selection](../docs/operations/installation.md).
