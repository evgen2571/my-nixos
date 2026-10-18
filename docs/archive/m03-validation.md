# M03 validation and readiness

Issue [#30](https://github.com/evgen2571/my-nixos/issues/30), 2026-10-18,
Nix 2.34.8, x86_64-linux. Changes are documentation only: no declarative host
behavior, generated configuration or mutable runtime state was changed.

## Recorded M03 revision pair and comparison boundary

The host/build/VM results below were recorded for the original M03 work delivered
in `c1ca4bf`, before the documentation revision. They were **not rerun** for that
revision; its checks are listed separately at the end.

Public configuration baseline: `pre-cleanup-history`.
The M03 documentation tree retains that configuration and public lock. The actual
owner private checkout was clean and its remote visibility verified **PRIVATE**.
All personal checks/builds selected the pinned private Git revision
`0782f09f79ab87b75a446b3fe282ae7e06051f53` explicitly using
`--override-input private 'git+file:///…/my-nixos-private?rev=0782f09f79ab87b75a446b3fe282ae7e06051f53' --no-write-lock-file`.
This includes the M02.5 metadata extraction and subsequent certificate relocation;
the empty public default and old ciphertext-only private revision are not substitutes.
Neither private sources nor raw host snapshots are published here.

Historical [M02 evidence](m02-validation.md) compares against pre-split
`pre-cleanup-history`.
[M02.5 evidence](m025-validation.md) records the metadata-extraction comparison,
using the then-current private `dcaace0027c8e9440847e8c3895cc80f03c9f236`.
Those are attributed historical runs, not fresh builds of the final pair.

M03 freshly evaluated all three credentialed host snapshots and compared them
to the protected M02.5 after-snapshots: **PC, laptop and server match**. The
projection is the same one used for M02.5, comparing public authorization-file
contents after relocation and normalizing only store hashes. It retains package
names/versions and runtime paths. Protected evidence stays under a mode-0700
local directory outside both repositories, with no secret decryption.

| Area | Comparison and evidence |
| --- | --- |
| Boot/storage | State versions, boot parameters/loader selection, filesystem devices/types/options and swap match M02.5; server `/srv/*` ownership remains as documented in [server operations](../guides/server.md) |
| Accounts/access | Primary name, UID/HOME/shell/groups, immutable-user/password policy, sudo, authorized keys and SSH settings match |
| Secrets | All SOPS declaration metadata, runtime paths, ownership/modes and `neededForUsers` match, excluding ciphertext source location |
| VPN/security | Complete namespace configuration, roles/peers, routes, IPv4/IPv6, DNS/filtering settings and host firewall match; isolated registered namespace/systemd checks cover behavior |
| Systemd | All service configuration/dependencies and system activation scripts match; this includes gateway transport/provider and sleep-guard service definitions |
| Home Manager/apps | HM username/HOME/state/session, Git/SSH, browser profile/workspace/pin IDs, Noctalia settings, activation derivation and managed file targets/executable flags match |

This is a bounded semantic comparison. Store-hash normalization does not prove
arbitrary source files are byte-identical; generated application data and mutable
databases are not compared. M02.5's recorded pre/post comparison remains the
evidence for intentional Noctalia serialization/source-ownership changes.

A wider fresh projection compared generated unit text/enabled flags (including
timers), PAM service text, Tailscale settings, WireGuard interfaces, host
resolver/IPv6 settings, initrd kernel modules/LUKS declarations, and HM file
source/text/targets plus activation scripts. PC, laptop and server each have
**zero changed projected fields**, after store-hash normalization, across all
three comparisons:

| Baseline public revision | Baseline private revision | Compared with |
| --- | --- | --- |
| Pre-split `pre-cleanup-history` | None; original local ciphertext | M03 tree with private `0782f09` |
| Pre-M02.5 `pre-cleanup-history` | `53a83456469cf2817c54317d15e652b5bc851105` | M03 tree with private `0782f09` |
| Post-M02.5 `pre-cleanup-history` | `0782f09f79ab87b75a446b3fe282ae7e06051f53` | M03 tree with the same private revision |

These fresh historical evaluations extend the earlier evidence across the split
and metadata extraction; historical toplevel builds were not rerun. Source-path
hash normalization intentionally tolerates moved/recomposed files, so the
Noctalia serialization comparison still relies on M02.5's separately parsed
settings evidence. This is ownership/definition parity, not a byte comparison of
all derivation outputs or runtime state. No original ciphertext was decrypted.

## Recorded M03 checks

Commands run from public my-nixos with no activation:

- A separate clean committed public clone, with no private override, SSH agent,
  GitHub token variables or SOPS identity environment: `nix flake show`, full
  `nix flake check`, and all three public toplevel derivation evaluations passed
  with `--no-write-lock-file`. Public inputs were available through the local Nix
  cache; this does not establish an uncached/offline bootstrap. Its lock stayed
  byte-identical. A public PC toplevel build failed with the intended
  `Deployment refused: existing host requires its private input` guard.
- `nix flake check --no-build --no-write-lock-file`: public checks evaluated.
- `nix flake check --no-write-lock-file`, public and with the pinned owner input:
  registered checks passed, including source policy, metadata, preflight/helper,
  config-path, Niri and namespace/module/systemd/recovery checks. Nix can reuse
  previously built check derivations; this is not a claim that every VM rebuilt.
- `nix build --no-link` for each of
  `nixosConfigurations.{nixos-pc,nixos-lp,nixos-server}.config.system.build.toplevel`
  with the pinned owner override: all three non-activating builds passed.
- `nix run .#shared-vpn-test --no-write-lock-file`: dedicated synthetic namespace
  fixtures passed.
- `nix shell nixpkgs#age nixpkgs#sops -c bash tests/migration/standalone.sh`:
  clean tracked-source template built in `none` and single-repository `local`
  modes with synthetic hardware, username and public login key. Its disposable
  KVM VM accepted key-only SSH and sudo. The actual guard accepted synthetic valid
  ciphertext/identity and refused unsafe permissions, a wrong identity and a
  missing identity. Missing encrypted fields and omitted first access were rejected.
  Synthetic private identities remained outside Git/store and were removed with
  the disposable fixture. The public lock stayed byte-identical.
- Documentation relative paths/anchors and fenced blocks passed validation;
  thirteen shell/Nix examples parsed in their documented context without executing
  installation/deployment commands. `git diff --check` passed.

The existing selector assertions exercise all three explicit modes with populated
local **and** private candidates, stale unselected local files, an unforced private
input in `none`, absent files, unknown selection, malformed maps, null entries and
metadata without ciphertext. Explicit selection chooses exactly one source; there
is no merge or implicit fallback. Policy tests reject plaintext/malformed encrypted
documents, missing required data and mismatched/broadened/reduced recipient scope.
Metadata assertions reject incomplete account/peer/SSH associations. Existing real
hosts retain `requirePrivate` regardless of source choice. Helper tests preserve
trailing flags and paths containing spaces through inert just/Fish commands.
The VM exercises root-owned identity permissions; ordinary non-root preflight
tests intentionally skip their root-only case.

## Acceptance and operator handoff

| Contract | Delivery |
| --- | --- |
| One-repository install with viable first access | [New machine without secrets](../getting-started/installation.md#new-machine-without-secrets): generated target hardware, builder registration, explicit boot/network/account policy, standard `nixos-install`, access verification |
| No secrets versus no private repository | [Source selection](../reference/secrets.md#source-selection) and tested none/local template; no production account-policy relaxation or credentialed-service fallback |
| Optional local SOPS | [Single-repository SOPS](../reference/secrets.md#single-repository-setup): own admin/host recipients, encrypted tracking, consumer files, runtime identity, permissions and metadata exposure |
| Private deployment readiness | [Deployment guards](../guides/deployment.md#deployment-guards), registered guard/source/metadata checks and synthetic VM preflight; target identity remains a separate prerequisite |
| Paired builds and flag forwarding | Pinned owner builds above, existing helper tests, [reviewed input selection](../guides/deployment.md#select-reviewed-inputs); no personal public-lock override |
| Fresh/restored bootstrap and rollback | [Operator checklists](../guides/deployment.md): all three targets, guarded installer, identity restoration and `neededForUsers`, independent access, tested-backup requirement, guarded upgrade and generation rollback |
| Ordinary development | [Ongoing changes](../getting-started/installation.md#keep-it-working): public modules/profiles/dotfiles, local ciphertext or owner input; one build root |

## Limits and readiness decision

The repository is ready for **operator review of installation/deployment**, not an
assertion of live parity. No real host was contacted or activated, no real identity
or decrypted credential was inspected, and no disks were formatted/installed.
Production decryption, real SSH/console access, hardware/boot, Tailscale enrollment,
provider egress/DNS containment and failures, gateway suspend/resume, mutable-state
backup restoration and rollback remain operator-run checks. Instructions requiring
tested backups are prerequisites, not a claim that backups were restored here.

Synthetic login/preflight/namespace tests cannot establish those live outcomes.
Preserve runtime identities, user/application data and persistent desktop provider
masks. An unavailable private input is never permission to bypass guards.
[Agent execution rules](../../AGENTS.md#live-state-and-sensitive-data) require
separate authorization for live operations; operator procedures mark their effects
in the maintainer guide. Issue #31's publication audit remains separate; these
checks do not authorize a repository visibility change.

## PR #41 documentation revision

This revision follows the Project direction in the latest README on main
(`pre-cleanup-history`): existing personal hosts are primary; independent adaptation is a
supported secondary path. The installation page now routes both readers, with
source/SOPS details and maintainer operations kept in their focused references.
The original M03 evidence above is preserved as recorded evidence.

Performed during this documentation revision:

- Checked 76 relative links/anchors, including 23 incoming references, and balanced
  fenced blocks. Verified the official NixOS manual's installation target and the
  issue reference.
- Parsed 19 shell/Nix examples without executing installation/deployment commands.
  Also applied the documented key-list replacement, firewall/sudo additions and
  output registration to the actual template/builder and checked Nix parsing.
- Reviewed the newcomer and existing-host maintainer paths separately; corrected
  their findings and confirmed no remaining actionable reader issues.
- Ran `git diff --check`; confirmed all revision edits are Markdown and
  `flake.lock`, host/runtime configuration, modules, tests and architecture code
  are unchanged.

Host evaluation/builds, VM login, production decryption and live operations were
**not rerun** during this revision. Their earlier results and limitations remain
recorded above; command parsing does not establish installation or runtime safety.
