# Maintain and check your configuration

Run these commands from your `my-nixos` checkout. The examples use the `my-host`
output from [installation](installation.md). Replace it with
your own output name. For my production PC, laptop, and server, use the
[deployment guide](deployment.md) instead: those builds require a reviewed,
explicit private input.

## Check before activation

1. Inspect `git status` and `git diff`. Confirm which host and subsystem changed.
   Stage new files so the Git flake includes them; commit only encrypted secrets
   and public keys, never private identities or plaintext credentials.
2. Enter the development shell if you need its Nix formatting and analysis tools:

   ```sh
   nix develop
   nix fmt
   git diff --check
   ```

   Review the formatter's diff; it can touch unrelated files. The shell doesn't
   include every test dependency or `just`. Direct Nix commands work without `just`.
3. Evaluate the flake, then execute registered checks when the environment supports them:

   ```sh
   nix flake check --no-build --no-write-lock-file
   nix flake check --no-write-lock-file
   ```

   The first command evaluates checks without running their programs. The second
   builds check derivations or uses cached results. `flake/verification.nix`
   registers migration/source-policy, metadata, Niri, config-path, and VPN checks,
   including a systemd VM test. Report what actually ran; an evaluated derivation
   isn't an executed test. Neovim has a separate `tests/neovim/run.sh` harness
   requiring provisioned plugins and an isolated test environment.
4. Build the affected host without activation:

   ```sh
   nix build --no-link .#nixosConfigurations.my-host.config.system.build.toplevel --no-write-lock-file
   git diff --exit-code -- flake.lock
   ```

   A successful build creates a system closure in the store. It doesn't prove
   boot, SSH access, graphical behavior, secret decryption, or real VPN egress.
   Shared modules need coverage of all affected hosts. If you use `local` or
   `private` credentials, retain the selected source throughout validation and
   deployment; see [source selection](secrets.md#source-selection).

## Apply a reviewed change

Activation changes the running system and can restart services. Before changing
boot, storage, networking, authentication, or secrets, keep an independent
console/SSH session, a known-good generation, and tested backups of mutable data
and protected identities. Record `readlink -f /run/current-system` and
`sudo nix-env --list-generations --profile /nix/var/nix/profiles/system`.

On the matching host, after reviewing the build:

```sh
sudo nixos-rebuild switch --flake .#my-host --no-write-lock-file
```

For this independent `none`/`local` host, no private override is needed. If you
chose a private input, use the same reviewed override as the build. For
display-manager changes, prefer a planned next-boot deployment with console
access; see [the greeter guide](noctalia-greeter.md#deploy-and-recover).
Agents need explicit authorization for any live activation.

After activation, run `systemctl --failed`, check the changed application or
service, and test a second login and `sudo -v` before closing recovery access.
A successful switch alone doesn't verify the application works.

## Update dependencies deliberately

`flake.lock` pins dependency revisions. To update just Nixpkgs:

```sh
nix flake update nixpkgs
```

Review the lock diff, then repeat the checks and host build before activation.
Other inputs have their own names in `flake.nix`; a full `nix flake update`
updates all inputs and needs broader review. Keep `system.stateVersion` and
`home.stateVersion` stable during routine upgrades. They select compatibility
defaults and aren't version numbers to bump along with Nixpkgs.

Commit reviewed source and lock changes together. Keep personal private-input
URLs out of the public lock, and keep known-good generations and their input
revisions until you're confident recovery is possible. Garbage collection can
remove the closure you were relying on for rollback.

## Recover after a failed change

Before activation, return to your known-good source revision and rebuild; this
changes no running system. After activation, if the immediately previous
generation is the recorded working one, an operator can run:

```sh
sudo nixos-rebuild switch --rollback
```

This changes live state. Otherwise select the recorded generation through the
console boot menu, recover access, and rebuild from its source revision. For my
production hosts follow the [full recovery procedure](deployment.md#rollback-and-recovery)
with the matching public/private revision pair.

Generation rollback restores system configuration. It doesn't restore databases,
browser sessions, generated themes, secrets, Tailscale enrollment, or persistent
VPN provider masks. Restore mutable data from its own backups. Keep the VPN masks
and safeguards intact, and don't turn an existing production host into a
secretless rescue configuration to bypass a refused deployment.
