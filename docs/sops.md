# sops secrets

This repository uses [sops-nix](https://github.com/Mic92/sops-nix) with age.
At activation, each NixOS host derives its decryption identity from its own
`/etc/ssh/ssh_host_ed25519_key`. The private host key stays on the host.

| NixOS configuration | Secret file |
| --- | --- |
| `nixos-pc` | `secrets/hosts/pc.yaml` |
| `nixos-lp` | `secrets/hosts/laptop.yaml` |
| `nixos-server` | `secrets/hosts/server.yaml` |

## Add recipients

Get the public age recipient from each host's SSH Ed25519 public key:

```bash
nix shell nixpkgs#ssh-to-age -c sh -c \
  'ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub'
```

Run that command on `nixos-pc`, `nixos-lp`, and `nixos-server`, then record the
three resulting `age1...` recipients in `.sops.yaml`. Add your personal/admin
age recipient there too. It must appear in every creation rule so it can edit
and recover every file.

Replace the empty structure in `.sops.yaml` with this shape, substituting only
real recipients:

```yaml
keys:
  - &admin age1ADMIN_RECIPIENT
  - &pc age1PC_HOST_RECIPIENT
  - &laptop age1LAPTOP_HOST_RECIPIENT
  - &server age1SERVER_HOST_RECIPIENT

creation_rules:
  - path_regex: secrets/common\.yaml$
    key_groups:
      - age:
          - *admin
          # Add only hosts that consume a common secret.
          - *pc
  - path_regex: secrets/hosts/pc\.yaml$
    key_groups:
      - age:
          - *admin
          - *pc
  - path_regex: secrets/hosts/laptop\.yaml$
    key_groups:
      - age:
          - *admin
          - *laptop
  - path_regex: secrets/hosts/server\.yaml$
    key_groups:
      - age:
          - *admin
          - *server
```

The sample must not be used unchanged. `age1ADMIN_RECIPIENT` and the other
values are labels, not valid recipients.

## Create and edit encrypted files

After `.sops.yaml` has real recipients, create a file with `sops`:

```bash
nix shell nixpkgs#sops -c sops secrets/hosts/server.yaml
```

Sops opens an editor and writes only encrypted content to the repository.
Repeat with `secrets/common.yaml` or the matching host file. To edit an
existing file, run the same command with its path.

Keep declarations next to their consumer. For example, a server service that
uses `example-token` should declare it in that service module or in
`hosts/server/configuration.nix`:

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

The secret path is consumed at runtime. Do not read a secret with
`builtins.readFile`, interpolate its value into Nix configuration, or place it
in the Nix store.

For a user password hash needed before normal activation, keep the declaration
at the user consumer and mark it early:

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

Store a password hash, never a plaintext password, in that secret.

## Rotate recipients

Update the recipient list in `.sops.yaml`, then refresh the encrypted file's
metadata for every file affected by that rule:

```bash
nix shell nixpkgs#sops -c sops updatekeys secrets/hosts/server.yaml
```

Run `sops updatekeys` once for each relevant file. Review the diff before
committing it. Removing a host from a rule and updating the file revokes its
ability to decrypt future revisions.

## Rebuild a host

Format and evaluate the target configuration before switching it:

```bash
nix fmt
git diff --check
nixos-rebuild build --flake .#nixos-server
sudo nixos-rebuild switch --flake .#nixos-server
```

Use `nixos-pc` or `nixos-lp` for those hosts. The host SSH private key must
exist at `/etc/ssh/ssh_host_ed25519_key` before sops-nix installs secrets.
