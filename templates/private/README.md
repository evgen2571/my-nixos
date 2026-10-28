# Private input

This is the empty private flake used when no personal input is selected. Copy it
into your own private repository if you want host overrides and encrypted secrets.

A private flake can provide host-specific overrides and SOPS ciphertext:

```nix
outputs = { self }: {
  nixosModules.pc = ./hosts/pc.nix;
  secretFiles.pc = ./secrets/hosts/pc.yaml;
};
```

I keep reusable modules, app enable switches, and shared app settings in the public repo.
Private host overrides select which apps use VPN network namespaces.
Machine-specific IDs, accounts, private endpoints, Zen layouts, and Dolphin Places
go in private overrides. Zen uses `programs.zen-browser.profiles.default.spaces`
and `.pins` (`isEssential = true` for Essentials); Dolphin uses
`my.user.files.dolphin.places`. See [Zen](../../config/zen/README.md) before
managing an existing browser profile.

Keep credentials in SOPS-encrypted files. Private Nix modules still enter the Nix
store, so plaintext secrets and private keys don't belong in them.

Check the repository's private visibility before copying personal data. Build from
the public checkout and keep your private input URL out of the public `flake.lock`.
See [secrets](../../docs/secrets.md) for setup and
[maintenance](../../docs/maintenance.md) for the `just` commands.
