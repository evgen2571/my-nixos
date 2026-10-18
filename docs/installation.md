# Installation and sensitive inputs

`my-nixos` is the main flake and sole build/deployment root. Real PC, laptop and
server hosts, profiles, discovery, Home Manager and dotfile layout remain here.
Tested input syntax requires Nix 2.34.8; older relative-path lock behavior is not
verified. New installations use [templates/host](../templates/host/README.md).
Disk partitioning, firmware/bootloader, networking and first access are explicit
operator choices; this migration does not automate provisioning.

## Three explicit source modes

Each `mkHost` call in `flake/hosts.nix` sets `secretSource` before module import:

| Choice | Material consumed | Missing material |
| --- | --- | --- |
| `none` | Neither local ciphertext nor private host modules | New-host bootstrap; requires explicit first-login configuration |
| `local` | Tracked `secrets/hosts/<host>.yaml` and `.sops.yaml` in this checkout | Error; never substitutes private data |
| `private` | Only `private.secretFiles.<host>` and optional `private.nixosModules.<host>` | Empty default permits evaluation; existing-host deployment unavailable |

There is no detection of sibling directories, runtime identities or stale local
files, and no merging/fallback. An explicit choice leaves other sources unselected
and ignored. Unknown choices, invalid paths, null supplied entries, overrides
without ciphertext and missing encrypted required fields fail. A build check validates encrypted top-level host scalars and age metadata even
without consumers, and checks local recipient-policy scope. sops-nix additionally
validates declared secret material at build time; a filename alone is not a valid secret.

For single-repository SOPS, use your own host copied from the template, select
`local`, create recipient rules in `.sops.yaml`, and encrypt `secrets/hosts/<host>.yaml`
with SOPS. Stage both before evaluation. Keep declarations beside consumers and
use the supplied `secretFile` argument for `sopsFile`. Add `neededForUsers = true`
for password hashes and consume only protected runtime paths. Keep host/admin
identities outside Git/store; provision `/var/lib/sops-nix/key.txt` securely before
installation. No second repository or private override is required. Manage your
own recipients; never reuse the maintainer's recovery documents or identities.

The committed `private` input is the tracked, empty `templates/private` flake. An
optional private repository exports just two maps, not another host builder.
See its [guide](../templates/private/README.md) for setup and pinned overrides.

## Existing production hosts

Existing outputs explicitly select `private` and keep `requirePrivate = true`.
Changing the source to `none` or `local` does **not** clear this requirement. With
the empty default, all outputs/checks evaluate, desktop accounts stay locked, and
VPN transport/provider startup is blocked while namespaces, firewall, resolver,
launcher isolation and desktop-provider guards remain declared. Old `/run/secrets`
files or mutable provider tokens cannot enable unavailable services.

A production toplevel with missing private input deliberately **fails its build**;
it cannot be installed, selected by nix-env or activated. This is stronger than a
pre-switch check and still permits public host/check evaluation. The evaluator's
`users.allowNoPasswordLogin` lockout assertion is suppressed only for these
unbuildable locked configurations; it does not enable passwordless login or change
`users.mutableUsers`. Credentialed configurations keep their original account policy.

With private material, `deployment-preflight` checks the target identity's ownership,
permissions and successful SOPS decryption to `/dev/null`, without logging values.
The target's `nixos-rebuild` checks this **before** selecting the system profile;
normal upstream rebuild re-exec selects this patched tool automatically. Native
NixOS pre-switch checks also protect direct `switch-to-configuration` calls.
Never use `--no-reexec`, an old absolute rebuild binary, `NIXOS_NO_CHECK`, manual
`nix-env --set`, or manual activation to bypass these guards. These are operator
bypasses, not supported deployment commands. A deliberate secretless recovery
requires its own reviewed procedure and independent console access.

For installation of an existing production output, use the matching guarded
installer built from the public flake's `system.build.nixos-install`; generic/old
installation-media tools do not have its pre-profile check. Provision the target
identity privately first, with root ownership, mode 0400/0600 and a root-owned
parent directory not writable by others. The guarded installer checks inside the
target root before selecting its first generation. It does not provision identities.
Installation writes disks/boot state and requires separate operator authorization.

## Non-activating development

From the public checkout:

```sh
nix flake show --no-write-lock-file
nix flake check --no-build --no-write-lock-file
nix flake check --no-write-lock-file
private_checkout=$(git -C ../my-nixos-private rev-parse --show-toplevel)
just build-pc --override-input private "git+file://$private_checkout" --no-write-lock-file
just build-lp --override-input private "git+file://$private_checkout" --no-write-lock-file
just build-server --override-input private "git+file://$private_checkout" --no-write-lock-file
```

`just build/dry/switch/boot HOST` and aliases accept trailing Nix/rebuild flags;
Fish `nb`, `nd`, `nsw`, `nboot` forward arguments after the host too. Only build
and dry-build are non-activating. Use the same explicit pinned private override
for any separately authorized deployment. Root/remote targets must have Git/store
access to the chosen source. Never embed credentials in URLs or modify the public
lock to record personal input selection.

The split removes selected data only at HEAD. History remains restricted pending
issue #31's publication audit. No visibility change, secret rotation or history
rewrite is part of installation or this implementation. Runtime/browser/editor
state is preserved and is not reconstructed by the flake.
