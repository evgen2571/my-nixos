# Private input

This template is the empty private flake used when no personal input is selected. You can also copy it into **your own private repository**.

A private flake can provide host-specific overrides and SOPS ciphertext:

```nix
outputs = { self }: {
  nixosModules.pc = ./hosts/pc.nix;
  secretFiles.pc = ./secrets/hosts/pc.yaml;
};
```

Keep reusable modules and ordinary app settings in the public repo. Machine-specific IDs, accounts, private endpoints, and **Zen spaces/pins/routes** go in the private overrides. The public Zen module still installs the browser and shared defaults; your private Home Manager options can fill in `programs.zen-browser.profiles.default.spaces` and `.pins`.

For an existing Zen profile, preserve the full existing workspace/pin definitions and UUIDs during the move. Don't merge the public Zen cleanup before the matching private definitions exist and both desktop builds have been checked.

Encrypted credentials belong in SOPS files. A private Nix module is still copied into the Nix store, so don't put plaintext secrets or private keys in it.

Build from the **public** checkout:

```sh
nix flake check --override-input private "git+file:///absolute/path/to/private-checkout" --no-write-lock-file
```

Check the private repo's visibility before copying any personal data. Never record the personal input URL in the public `flake.lock`.
