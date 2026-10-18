# SOPS secrets

See [installation and source modes](installation.md) before choosing `none`,
`local` or `private`. All builds/deployments start in **my-nixos**. Maintainer
ciphertext, recipient associations and admin-only recovery documents now live in
the optional private input; public Git history still requires its separate audit.

Standalone users can keep their own encrypted `secrets/hosts/<host>.yaml` and
`.sops.yaml` in this checkout. Select `local` explicitly in that host's `mkHost`
call. Neither the empty template nor local files override a private selection.
Stage new encrypted/policy files: Git flakes omit untracked files.

## Identities and recipient policy

Each host uses a dedicated age identity at `/var/lib/sops-nix/key.txt`, outside
Git and the Nix store. Existing identities must be preserved. The shared module
retains sops-nix generation support, but **production preflight requires an
already securely provisioned identity**, including before first installation.
Do not attempt a secretless production switch merely to generate it.

For a new host, create/provision its identity through your trusted console or
protected installer workflow, root-owned with mode 0400/0600 and a root-owned
parent not writable by others. Derive only its **public** recipient with
`age-keygen -y /var/lib/sops-nix/key.txt`; do not print/copy the identity. Keep a
separate protected admin identity for editing/recovery and back it up privately.

Write `.sops.yaml` rules using your real public recipients. Each host file should
include only the admin and that host. Recovery/bootstrap identity documents are
admin-only, never exposed through `secretFiles` or broadened to host recipients.
No rekey is needed when unchanged encrypted files retain their paths in another
repository. Never invent recipients or decrypt documents to relocate them.

## Editing and consumers

Run SOPS from the repository owning the selected ciphertext, for example
`nix shell nixpkgs#sops -c sops secrets/hosts/my-host.yaml`. Use its protected age
identity configuration; do not pass credentials as arguments or Nix values.
Commit only encrypted documents and review recipient metadata deliberately.

Declare consumers beside their host/service:

```nix
{ config, lib, secretFile, ... }: {
  sops.secrets = lib.mkIf (secretFile != null) {
    example-token = {
      sopsFile = secretFile;
      key = "example_token";
      owner = "example-service";
      mode = "0400";
      restartUnits = [ "example-service.service" ];
    };
  };
  # Guard the dependent service too; never substitute plaintext or host networking.
}
```

Consume `config.sops.secrets.<name>.path` only when declared. For password hashes
needed before users are created, retain `neededForUsers = true`; without a password
secret keep the account locked. Runtime API keys, SSH/WireGuard private keys,
provider tokens and hashes must never be read into Nix expressions, generated
source files or derivation arguments. `builtins.readFile` may validate ciphertext,
never decrypted runtime paths. Existing owners, modes, paths and restarts are unchanged.

## Rekeying and deployment

For an intentional recipient change, update the owning `.sops.yaml`, run
`sops updatekeys` on affected documents using an authorized identity, and review
the encrypted diff. Revocation cannot erase historical copies. Identity loss or
rotation requires a separately planned recovery; do not replace working identities
as part of this migration.

Evaluate, run full checks and build without activation using the selected source.
Existing production hosts require the explicit private override and mandatory
readiness checks described in [installation](installation.md). Preflight decrypts
to `/dev/null` at deployment time to verify the protected identity, without exposing
values. Successful evaluation/build does not authorize activation, test real VPN
egress, or provision mutable provider refresh tokens.
