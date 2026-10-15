# SOPS secrets

This repository uses [sops-nix](https://github.com/Mic92/sops-nix) with a
dedicated age identity on every NixOS host. The shared module generates and
reads that identity at `/var/lib/sops-nix/key.txt`; SOPS decryption does not
depend on an OpenSSH host key.

| NixOS configuration | Secret file |
| --- | --- |
| `nixos-pc` | `secrets/hosts/pc.yaml` |
| `nixos-lp` | `secrets/hosts/laptop.yaml` |
| `nixos-server` | `secrets/hosts/server.yaml` |

VPN private keys live separately in `secrets/vpn/<host>.yaml`, encrypted only to
the administrator and that host. Public WireGuard keys are declarative in
`hosts/vpn-public-keys.nix`. Server authentication uses the server VPN file; its
currently empty bootstrap token must be privately provisioned before deployment.

Use `secrets/common.yaml` only for a value genuinely consumed by multiple
hosts. Keep every `sops.secrets` declaration next to the host or service that
consumes it.

Encrypted SOPS YAML and public `age1...` recipients are intended to be
committed. Plaintext secrets, decrypted working copies, and private age keys
must never be committed. Public values such as usernames, hostnames, SSH public
keys, Git identity, and age recipients remain ordinary configuration rather
than being moved into SOPS.

## Bootstrap the recipients

The active `.sops.yaml` already declares the administrator and three dedicated
host recipients. The steps below describe initial setup for a new host; do not
replace existing host identities or working recipients. Never invent recipients.

### 1. Generate each host identity

Rebuild and activate the current configuration once on each host. With no
secret declarations yet, sops-nix creates its dedicated identity during
activation:

```bash
sudo nixos-rebuild switch --flake .#nixos-pc
sudo nixos-rebuild switch --flake .#nixos-lp
sudo nixos-rebuild switch --flake .#nixos-server
```

Run only the command matching the host you are currently using. Each host must
retain and protect `/var/lib/sops-nix/key.txt`; losing it removes that host's
ability to decrypt files addressed to it.

### 2. Derive each host's public recipient

On each host, print the public recipient from its generated identity:

```bash
sudo nix shell nixpkgs#age -c \
  age-keygen -y /var/lib/sops-nix/key.txt
```

Record the resulting `age1...` value as the recipient for `pc`, `laptop`, or
`server`. This public value is safe and intended to be committed; the contents
of `key.txt` are private and must never leave the host or enter Git.

### 3. Create and back up an admin identity

On the trusted administrator workstation, create a separate identity used to
edit and recover every encrypted file:

```bash
install -d -m 0700 ~/.config/sops/age
nix shell nixpkgs#age -c \
  age-keygen -o ~/.config/sops/age/keys.txt
chmod 0600 ~/.config/sops/age/keys.txt
nix shell nixpkgs#age -c \
  age-keygen -y ~/.config/sops/age/keys.txt
```

Record the final `age1...` output as the admin recipient. Back up
`~/.config/sops/age/keys.txt` in a secure, offline or encrypted location. The
backup is private key material and must not be committed.

### 4. Activate `.sops.yaml`

Replace every placeholder in the commented template in `.sops.yaml` with its
real public recipient, then uncomment the template and remove the active empty
`keys: []` and `creation_rules: []` lines. The admin belongs in every rule; a
host-specific file gets only the admin and that host. In the `common.yaml`
rule, list only the hosts that actually consume its values.

Do not proceed while strings such as `age1ADMIN_RECIPIENT` remain. A configured
host rule has this shape:

```yaml
keys:
  - &admin age1REAL_ADMIN_RECIPIENT
  - &server age1REAL_SERVER_RECIPIENT

creation_rules:
  - path_regex: secrets/hosts/server\.yaml$
    key_groups:
      - age:
          - *admin
          - *server
```

The example values above are deliberately invalid placeholders, not keys to
copy.

## Create and edit encrypted files

After `.sops.yaml` contains real recipients, use the admin identity to create
or edit the matching encrypted file:

```bash
nix shell nixpkgs#sops -c sops secrets/hosts/server.yaml
```

Use `secrets/hosts/pc.yaml` or `secrets/hosts/laptop.yaml` for the other hosts.
VPN private keys live separately in `secrets/vpn/<host>.yaml`, encrypted only to
the administrator and that host. Public WireGuard keys are declarative in
`hosts/vpn-public-keys.nix`. Server authentication uses the server VPN file; its
currently empty bootstrap token must be privately provisioned before deployment.

Use `secrets/common.yaml` only when more than one configured host consumes the
same value. SOPS opens an editor and saves encrypted YAML; inspect the result
before committing to ensure no plaintext value remains.

SOPS finds the admin key at its default age identity path,
`~/.config/sops/age/keys.txt`. If the key is stored elsewhere, set
`SOPS_AGE_KEY_FILE` for the command without copying the key into this
repository.

## Declare and consume a secret

Declare a secret next to its consumer, not in `modules/secrets.nix`. For
example, a server service can use a key from its host file:

```nix
{ config, ... }:

{
  sops.secrets.example-token = {
    sopsFile = ../../secrets/hosts/server.yaml;
    owner = "example-service";
    group = "example-service";
    mode = "0400";
  };

  systemd.services.example-service.serviceConfig = {
    LoadCredential = "token:${config.sops.secrets.example-token.path}";
  };
}
```

Consume the runtime path through `config.sops.secrets.<name>.path`. Do not use
`builtins.readFile`, interpolate the secret value into Nix configuration, or
otherwise place plaintext in the Nix store.

For a user password hash required before normal activation, declare it at the
user consumer and set `neededForUsers = true`:

```nix
{ config, ... }:

{
  sops.secrets.primary-user-password-hash = {
    sopsFile = ../../secrets/hosts/server.yaml;
    neededForUsers = true;
  };

  users.users.server.hashedPasswordFile =
    config.sops.secrets.primary-user-password-hash.path;
}
```

Store a password hash, not a login password, in that secret.

## Rotate or rekey recipients

To grant or revoke access, update the public recipient list in `.sops.yaml`,
then rekey every affected encrypted file:

```bash
nix shell nixpkgs#sops -c \
  sops updatekeys secrets/hosts/server.yaml
```

Run `sops updatekeys` for every file whose rule changed and review each diff.
Removing a recipient and updating the encrypted file prevents that identity
from decrypting future revisions; it cannot erase copies of old ciphertext or
plaintext already held by that recipient.

If a host identity is lost or intentionally rotated, rebuild to generate a new
`/var/lib/sops-nix/key.txt`, derive its new public recipient, replace the old
recipient in `.sops.yaml`, and run `sops updatekeys` using an identity that can
still decrypt the existing files (normally the admin key).

## Validate and rebuild

Before activation, format, check, and build the target configuration:

```bash
nix fmt
git diff --check
nix flake check
nix build .#nixosConfigurations.nixos-server.config.system.build.toplevel
```

Use `nixos-pc` or `nixos-lp` for the other hosts. After a successful build,
activate only on the matching machine with `sudo nixos-rebuild switch`.
