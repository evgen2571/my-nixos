# Secrets

You don't need my private repository to use these modules.

Each host in `flake/hosts.nix` chooses one source:

| Source | Use it for |
| --- | --- |
| `none` | A new host without secret-dependent services |
| `local` | Your own SOPS-encrypted file in this repo |
| `private` | A separate private flake with host overrides and encrypted files |

For your first host, use `none`. The [host guide](../hosts/README.md#5-configure-the-machine-and-user)
uses a protected runtime password hash file for login and sudo, so you can start
without SOPS. Keep that file outside the checkout, even when Git would ignore it:
path flakes can copy ignored files into the Nix store.

A service that needs credentials must stay off until those credentials exist.

With `local`, keep the host's encrypted document in `secrets/hosts/<host>.yaml` and recipient rules in `.sops.yaml`. The host's protected age identity lives at `/var/lib/sops-nix/key.txt`, **not in Git**. Keep a separate admin identity somewhere protected so you can edit and recover the encrypted file. See [sops-nix](https://github.com/Mic92/sops-nix) for key generation and the complete setup.

With `private`, the second flake exports `nixosModules.<host>` and `secretFiles.<host>`. Start from [the private template](../templates/private/README.md). The public checkout remains the build root; the private flake just supplies host-specific pieces.

```sh
nix flake check --override-input private "git+file:///absolute/path/to/my-nixos-private" --no-write-lock-file
```

Some of my existing hosts have guards that deliberately refuse a production build without their private input. Don't switch those outputs to `none` as a workaround.

**Private Git doesn't mean secrets are safe in Nix strings.** Nix source can enter the store. Put credentials in encrypted SOPS documents or protected runtime files, not in module options or application configs. Keep and back up original host identities; a newly generated age key won't decrypt old files.
