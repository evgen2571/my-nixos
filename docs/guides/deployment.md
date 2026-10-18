# Maintainer builds, deployment and recovery

Start here for the existing `nixos-pc`, `nixos-lp` and `nixos-server`. Run commands
from the public `my-nixos` checkout on the matching host, using normal host
networking. For another machine, use [host adaptation](../getting-started/installation.md#new-machine-without-secrets).

| Task | Procedure | Effect |
| --- | --- | --- |
| Select revisions, check and rebuild | [Inputs](#select-reviewed-inputs), then [build](#build-without-activation) | Checkout changes, checks and store builds; no activation |
| Apply an update | [Upgrade](#upgrade-an-existing-host) | Changes the running system and selected generation |
| Reinstall/restore a host | [Restore](#restore-an-existing-host) | Writes the mounted target and boot state |
| Recover after a failed update | [Rollback](#rollback-and-recovery) | Can change the running/booted generation |

**For agents:** live installation, activation, identity changes and rollback require
separate explicit authorization under [AGENTS.md](../../AGENTS.md#deployment-security-and-data-safety).
The warnings below describe operational effects for any reader.

## Select reviewed inputs

Use compatible public/private commit IDs, including the post-M02.5 account and
peer metadata. Run from a clean checkout; `git checkout` changes source files:

```sh
git checkout REVIEWED_PUBLIC_COMMIT
private_checkout=$(git -C ../my-nixos-private rev-parse --show-toplevel)
private_rev=$(git -C "$private_checkout" rev-parse HEAD)
private_input="git+file://$private_checkout?rev=$private_rev"
# Or use a reviewed full commit ID in an authenticated Git input:
# private_input='git+ssh://git@github.com/evgen2571/my-nixos-private?rev=REVIEWED_PRIVATE_COMMIT'
sha256sum flake.lock
```

Check `private_rev` against the reviewed pair before continuing. The invoking user
and root/remote builder need Git/store access; acquire inputs before maintenance.
Never embed credentials in URLs or record personal overrides in the public lock.
The [private template](../../templates/private/README.md) defines the input interface.

## Build without activation

These commands evaluate/check or create store outputs; they do not select a
system generation or restart services:

```sh
nix flake show --no-write-lock-file
nix flake check --no-build --no-write-lock-file
nix flake check --override-input private "$private_input" --no-write-lock-file
```

`--no-build` evaluates checks only. The full command runs registered checks
(or reuses their cached results). Build the affected host:

| Target | Non-activating command |
| --- | --- |
| PC | `just build-pc --override-input private "$private_input" --no-write-lock-file` |
| Laptop | `just build-lp --override-input private "$private_input" --no-write-lock-file` |
| Server | `just build-server --override-input private "$private_input" --no-write-lock-file` |

`just` is a separate prerequisite. Its [recipes](../../justfile) use
`nix build .#nixosConfigurations.HOST.config.system.build.toplevel`.
Check `git diff --exit-code -- flake.lock` afterward. Successful builds do not
establish target decryption, hardware boot or provider health; recorded results
and limits are in [M03 validation](../archive/m03-validation.md).

Helpers forward trailing flags: `just build/dry/switch/boot HOST` and Fish
`nb`/`nd`/`nsw`/`nboot`. Build and dry-build leave generation selection unchanged;
`switch` changes the running system, while `boot` selects the next boot generation.
Use the same reviewed pinned input for any later deployment.

## Upgrade an existing host

**Changes live system state.** Before running a switch:

- Keep independent console/host-network SSH access and a second working session.
  Record `readlink -f /run/current-system` and
  `sudo nix-env --list-generations --profile /nix/var/nix/profiles/system`.
  Preserve the known-good generation and source pair from garbage collection.
- Verify backups by restoring samples into protected scratch storage: original
  age identity, ciphertext/policy, SSH client identity and mutable application data.
  See [SOPS identity requirements](../reference/secrets.md#identities-and-recipient-policy).
- For the server, verify `findmnt -T /srv/storage`, `findmnt -T /srv/appdata`,
  `findmnt -T /srv/backups` and `findmnt -T /srv/compose`. Sibling `/srv/*` paths
  are not implicitly on the storage mount. Confirm application-consistent backups
  and coordinate gateway maintenance with both clients; see [server operations](server.md).

Run **only** the command for the host you are updating, from its public checkout:

```sh
# PC
sudo nixos-rebuild switch --flake .#nixos-pc --override-input private "$private_input" --no-write-lock-file
# Laptop
sudo nixos-rebuild switch --flake .#nixos-lp --override-input private "$private_input" --no-write-lock-file
# Server: coordinate the gateway maintenance window first.
sudo nixos-rebuild switch --flake .#nixos-server --override-input private "$private_input" --no-write-lock-file
```

Use normal target rebuild re-exec and retain the [deployment guards](#deployment-guards).
A guard refusal means stop and restore the required material, not select `none`.

### Verify before closing recovery access

For every host, compare `readlink -f /run/current-system` with the reviewed build;
check `systemctl --failed`, `id`, `sudo -v`, HM activation and a **second** SSH login.
Check secret ownership/modes with `stat`, never by printing secret values.

| Host | Additional checks |
| --- | --- |
| PC | Original user/HOME and mounts, desktop login, browser/session continuity, editor/Matugen preservation |
| Laptop | The same desktop checks, plus Wi-Fi/host-network reachability and power state |
| Server | Each used `/srv/*` mount; `systemctl status sshd tailscaled docker syncthing --no-pager`; `tailscale status`; `systemctl is-enabled server-night-suspend.timer` stays disabled/absent in gateway role; `systemctl status server-morning-wake.timer --no-pager` matches wake policy |

On desktops, inspect `systemctl show hide-me-vpn.service netns-vpn-underlay.service
-p LoadState -p ActiveState`: legacy providers remain masked/inactive. On all hosts,
use `vpn-status --verbose` and `sudo /etc/network-namespaces/vpn-check` as described
in [VPN operations](shared-vpn-gateway.md#read-only-status-and-diagnosis). Verify
both clients after gateway changes. Real IPv4/IPv6 containment, isolated DNS and
provider failure/recovery tests need a planned live acceptance window; synthetic
checks do not establish them. Do not restart services speculatively.

## Restore an existing host

**Writes target disks/profile/boot state.** For each of `nixos-pc`, `nixos-lp` and
`nixos-server`, verify the physical target and its hardware/mount/boot declarations.
Follow the [NixOS installation manual](https://nixos.org/manual/nixos/stable/#sec-installation)
for disk preparation and mounting. Do not apply an existing host layout elsewhere.

1. Select the reviewed input pair and complete its non-activating build above.
2. Restore the **original** host age identity into `/mnt/var/lib/sops-nix/key.txt`:
   root-owned, mode 0400/0600, in a real root-owned mode-0700 directory. Restore
   ciphertext through the private input, not into the identity file. Confirm the
   backed-up SSH client identity matches the authorized public key association.
3. Desktop password hashes use SOPS `neededForUsers`; the identity must exist
   before activation/user creation. Do not assume the server has a desktop password.
   Arrange console access and Tailscale enrollment before relying on tailnet-only SSH.
4. Build the matching **guarded installer**, then run it against the reviewed
   mounted target. Choose `target=nixos-pc`, `nixos-lp` or `nixos-server`:

   ```sh
   target=nixos-server
   # Store build only:
   installer=$(nix build --no-link --print-out-paths \
     ".#nixosConfigurations.$target.config.system.build.nixos-install" \
     --override-input private "$private_input" --no-write-lock-file)
   # Writes the mounted target and boot state:
   sudo "$installer/bin/nixos-install" --root /mnt --flake ".#$target" \
     --override-input private "$private_input" --no-write-lock-file --no-root-passwd
   ```

   Confirm input access under sudo first. The matching installer checks protected
   identity/decryption in the target root before selecting its first generation;
   a generic/old installation-media tool lacks this integration. It does not
   provision the identity. Keep the console through boot and the checks above.

## Rollback and recovery

Before activation, returning to the known-good public commit/private revision
and rebuilding changes no running host. After activation, use independent
console/SSH access and the generation recorded for that particular machine.

**Changes live system state:** if the immediately previous generation is the
recorded known-good one, run:

```sh
sudo nixos-rebuild switch --rollback
```

Otherwise use the console boot menu to select the recorded generation (requires a
reboot), recover access, then rebuild from its known-good source pair. Restore
missing original identity/ciphertext before retrying a refused preflight; never
bypass guards or assume the most recent generation is safe.

Rollback does not restore databases, browser sessions, generated Matugen data,
provider tokens, Tailscale enrollment or persistent desktop provider masks. Keep
those masks: never return clients to historical local-provider behavior. Restore
mutable data with its reviewed backup procedure and repeat access/mount/VPN checks;
server recovery also requires checking both clients. Deliberately secretless rescue
needs a separate reviewed configuration with explicit access and disabled dependent
services; it is never an automatic production fallback.

## Deployment guards

Existing outputs select `private` and retain `requirePrivate = true`, even when
source selection is edited. Empty-default outputs/checks evaluate, but their
production toplevel **cannot build, be installed or activate**. Accounts stay
locked; VPN transports/providers cannot start from stale `/run/secrets` files or
mutable tokens. Namespaces, firewall/resolver and launcher/provider isolation remain
in place. The evaluation-only `users.allowNoPasswordLogin` assertion suppression
neither enables passwordless login nor changes `users.mutableUsers`.

With private material, `deployment-preflight` checks identity ownership/modes and
SOPS decryption to `/dev/null`, without logging values. The patched target rebuild
checks **before** profile selection; native pre-switch checks also protect direct
`switch-to-configuration`. Keep normal re-exec. `--no-reexec`, `NIXOS_NO_CHECK`, old
absolute rebuild tools, manual `nix-env --set` and manual activation are unsupported
bypasses. Installation uses the guarded installer described above.
