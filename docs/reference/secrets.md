# SOPS secrets and source selection

Use this reference when a host needs credentials. For a new host without secrets,
start with [installation](../getting-started/installation.md#new-machine-without-secrets). For the
maintainer's existing hosts, use [builds and deployment](../guides/deployment.md).
All builds start in public `my-nixos`; a second repository is optional.

## Source selection

Each `mkHost` call in `flake/hosts.nix` explicitly chooses one source:

| Mode | Selected material | If unavailable |
| --- | --- | --- |
| `none` | No ciphertext or private host modules | Keep credential-dependent services disabled; configure first access explicitly |
| `local` | Tracked `.sops.yaml` and `secrets/hosts/<host>.yaml` in this checkout | Error; no private fallback |
| `private` | `private.secretFiles.<host>` and optional `private.nixosModules.<host>` | Empty default permits evaluation; existing-host deployment unavailable |

Unselected files/inputs are ignored, with no sibling-directory detection, merge
or fallback. Unknown modes, invalid paths/maps, null entries, metadata without
ciphertext and missing encrypted required fields fail. Builds check encrypted
host scalars and age metadata even without consumers, and local recipient scope;
sops-nix also validates declared secrets. A filename alone is insufficient.

The tracked `templates/private` flake is an empty default. Its
[two-map interface](../../templates/private/README.md) provides optional narrow
metadata and ciphertext, not another host builder. Existing outputs retain their
[private-material guards](../guides/deployment.md#deployment-guards) even if their
source mode is changed. See [metadata ownership](personal-metadata.md) for the
personal values supplied by that input.

## Identities and recipient policy

Ciphertext is not a decryption identity. Each host uses its own protected age key
at `/var/lib/sops-nix/key.txt`, outside Git and the Nix store. Preserve existing
identities; generating a new key cannot decrypt old documents. For restored
production hardware, follow [host restoration](../guides/deployment.md#restore-an-existing-host).
Although sops-nix supports key generation, production preflight requires the
original identity to be provisioned **before** installation or deployment.

Keep a separate protected admin identity for editing/recovery. Host documents
should have exactly that admin and the intended host as recipients. Recovery
identity documents remain admin-only and must not be exported through `secretFiles`.
Back up identities privately and test restoration into protected scratch storage.
Moving unchanged ciphertext between repositories needs no decryption or rekey.

## Single-repository setup

For your own host, select `secretSource = "local"` in its `mkHost` call. The
following steps change protected key files and encrypted checkout files; they do
not activate services. Never run them over an existing host identity.

### 1. Provision your own identities

Provide the tools with `nix shell nixpkgs#age nixpkgs#sops`. On a trusted workstation,
create an admin identity in a protected filesystem outside Git/store:

```sh
umask 077
age-keygen -o /protected/admin-age.txt
age-keygen -y /protected/admin-age.txt
```

On a trusted installer with the new target mounted at `/mnt`, create its host
identity. The explicit executable path also works when sudo resets `PATH`:

```sh
sudo install -d -o root -g root -m 0700 /mnt/var/lib/sops-nix
sudo "$(command -v age-keygen)" -o /mnt/var/lib/sops-nix/key.txt
sudo chmod 0600 /mnt/var/lib/sops-nix/key.txt
sudo "$(command -v age-keygen)" -y /mnt/var/lib/sops-nix/key.txt
```

Use `/var/lib/sops-nix` without `/mnt` on an already booted new host. The directory
must be real, root-owned and not writable by others; the key must be root-owned
with mode 0400/0600. Derive only public recipients with `age-keygen -y`; never
print the identity file. Preserve independent SSH/console access.

### 2. Encrypt and track the host document

Put the two actual **public** recipients in `.sops.yaml`:

```yaml
creation_rules:
  - path_regex: secrets/hosts/my-host\.yaml$
    age: ADMIN_PUBLIC_RECIPIENT,HOST_PUBLIC_RECIPIENT
```

From the checkout, create top-level scalar keys matching the consumers, such as
`example_token`. Use SOPS with an editor whose swap/backups stay protected:

```sh
mkdir -p secrets/hosts
SOPS_AGE_KEY_FILE=/protected/admin-age.txt sops secrets/hosts/my-host.yaml
git add .sops.yaml secrets/hosts/my-host.yaml
git ls-files .sops.yaml secrets/hosts/my-host.yaml
```

Git flakes omit untracked files. Inspect the staged diff privately: commit only
encrypted documents and recipient policy, never plaintext, password hashes,
private keys, editor backups or runtime tokens. Public ciphertext still exposes
names, recipient associations and change history. Check that recipient scope is
exactly the admin plus that host; automated policy checks do not prove ownership.

### 3. Declare and verify consumers

Keep declarations beside the owning service, using the selected `secretFile`:

```nix
{ config, lib, secretFile, ... }: {
  sops.secrets = lib.mkIf (secretFile != null) {
    example-token = {
      sopsFile = secretFile;
      key = "example_token";
      owner = "example-service"; # use the actual service account
      mode = "0400";
      restartUnits = [ "example-service.service" ];
    };
  };
  # Guard the dependent service too; never substitute plaintext or host networking.
}
```

Point the service's runtime credential-file option at
`config.sops.secrets.example-token.path`. Never read decrypted paths into Nix
expressions, generated sources or derivation arguments. Without credentials,
leave the dependent service disabled. Existing owners, modes and restarts stay intact.

Run the [non-activating host checks/build](../getting-started/installation.md#3-register-and-build).
This validates ciphertext/declarations, not production decryption. Provision the
protected target identity before installing. After boot, inspect only metadata:

```sh
sudo stat -c '%U %a %n' /var/lib/sops-nix/key.txt /run/secrets/example-token
```

### Console passwords

For a password hash needed before user creation, encrypt `user_password_hash` and
declare `sops.secrets.user-password` with that key, `sopsFile = secretFile` and
`neededForUsers = true`. Set the account's
`hashedPasswordFile = config.sops.secrets.user-password.path`; remove that new
account's explicit template `hashedPassword = "!"`. Retain a locked account when
its password secret is absent. Never place a password/hash literal in Nix or Git.

The host identity must exist before activation/user creation. A one-off `passwd`
is not durable with `users.mutableUsers = false`. A console-only adaptation must
replace the template's SSH assertion with its own validated provisioning rule;
do not relax account policy on the existing production hosts.

## Editing and recipient changes

Edit ciphertext in the repository owning it, using the protected admin identity:

```sh
SOPS_AGE_KEY_FILE=/protected/admin-age.txt sops secrets/hosts/my-host.yaml
```

For intentional recipient changes, update that repository's `.sops.yaml`, run
`sops updatekeys` on affected documents using an authorized identity, and review
the encrypted diff. Revocation cannot erase historical copies. Plan identity loss
or rotation separately; never replace working identities during this migration.

Existing-host deployment and decryption checks are in the
[maintainer guide](../guides/deployment.md). Source relocation removes selected
material only at HEAD; history remains subject to #31's separate publication audit.
