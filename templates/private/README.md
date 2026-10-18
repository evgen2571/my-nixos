# Optional private input

This tracked, dependency-free flake is the safe default. It exports empty
`nixosModules` and `secretFiles` maps, never hosts/builders/deployment outputs.
No second repository is required for a standalone installation.

For an optional private checkout, copy this directory into a repository whose
visibility you have verified PRIVATE **before** copying sensitive material.
Export narrow modules and encrypted files, keyed by public source host name:

```nix
outputs = { self }: {
  nixosModules.pc = ./hosts/pc.nix;
  secretFiles.pc = ./secrets/hosts/pc.yaml;
};
```

Modules supply only reviewed sensitive declarations, using native NixOS options
or `my.primaryUser.home.settings` for Home Manager. Keep feature selection,
hardware, source dotfiles and host assembly in my-nixos. Never duplicate entire
host definitions or dotfile trees. Do not export admin-only bootstrap documents.
Store only SOPS-encrypted credentials; input source files enter the Nix store,
even when Git is private. Never store plaintext passwords, hashes, identities or
tokens in either flake. Keep matching `.sops.yaml` recipient rules with ciphertext;
for example `path_regex: secrets/hosts/pc\.yaml$` with your admin and PC age
public recipients. Generate real recipients; ship no fake production keys.

Build/check from the **public** checkout, explicitly selecting the private input:

```sh
private_checkout=$(git -C ../my-nixos-private rev-parse --show-toplevel)
nix flake check --override-input private "git+file://$private_checkout" --no-write-lock-file
just build-pc --override-input private "git+file://$private_checkout" --no-write-lock-file
```

Stage new source/ciphertext files before evaluation. A Git input omits untracked
files; avoid a broad `path:` override of private working directories. For a
reproducible build, commit both repositories and append `?rev=COMMIT` to the
private URL. Never write this personal override into the public lock.

See [installation and source modes](../../docs/installation.md) for single-repo
SOPS, public evaluation and mandatory production deployment readiness checks.
