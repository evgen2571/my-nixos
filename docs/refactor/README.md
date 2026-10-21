# Feature-first refactor comparison contract

This records the pre-migration contract for [#50](https://github.com/evgen2571/my-nixos/issues/50)
and the remaining [#49](https://github.com/evgen2571/my-nixos/issues/49) series.
The exact functional baseline is `pre-cleanup-history`
(merged PR #48). The final typed-only architecture is described in [the final handoff](final-architecture.md). The integration branch is
`refactor/feature-first-modules`; its PR remains draft
until the rest of the series and final review. Do not merge or activate hosts.

Start with [the approved target tree](target-tree.md), then [the exhaustive inventory](inventory.json).
Current migration progress and #52 evidence are in [ordinary features and baselines](ordinary-features.md);
[complex features and #53 evidence](complex-features.md) and
[infrastructure and #54 evidence](infrastructure.md) cover subsequent stages.
`migrations.json` records the completed stage ledger for historical comparisons;
the final catalog and inventory check do not depend on it. The baseline evidence below stays unchanged.
The inventory records all 75 discovered entries, in the original catalog order,
with scope, profile eligibility, constituent files, option declarations, source
references for dependencies/deployment, related checks/docs, and target entry.
Its exhaustive file mappings include helpers, patches, scripts, packaging sources,
program-native assets, host profiles and assembly libraries, with SHA-256 and
executable-bit evidence. The source references are an audit aid, not a dependency
resolver; evaluated schemas below are authoritative for option interfaces.

## Ordering, availability and explicit assembly

[`catalog-baseline.json`](../../tests/module-equivalence/catalog-baseline.json)
was captured by evaluating the original catalog, before replacement discovery.
It contains all four ordered lists, including disabled modules. Never replace
these lists with a feature-path sort. Translate each original path through the
inventory and preserve its position, scope and eligibility. Directory paths in
the original catalog mean their `default.nix` entry, not every Nix file below it.

Explicit assembly is separate from discovered optional modules:

| Entry | Caller / eligibility | Target |
| --- | --- | --- |
| `modules/system-core/common.nix` | PC and laptop configurations; unconditional desktop baseline | `modules/core/desktop-baseline.nixos.nix` |
| `modules/system-core/server.nix` | Server configuration; unconditional boot/network/Nix baseline | `modules/core/server-baseline.nixos.nix` |
| `modules/system-core/user.nix` | All host configurations; `my.primaryUser.enable` gates wiring | `modules/core/primary-user.nixos.nix` |
| `home/default.nix` | Primary-user adapter; all hosts with home enabled | `modules/core/primary-user.home.nix` |
| `modules/secrets.nix` | `flake/hosts.nix`; all hosts, selected source arguments | `modules/core/secrets.nixos.nix` |
| `modules/deployment/default.nix` | `flake/hosts.nix`; all hosts, `requirePrivate` guard | `modules/deployment/nixos.nix` |

Keep host hardware/configuration/profile/secrets files and `hosts/common/desktop.nix`
in their current assembly roles. Shared desktop selections retain ordinary priority;
workstation bundle defaults retain `mkDefault`. Home Manager and sops-nix enter via
`flake/hosts.nix`. Keep shared special arguments, packageSources, private selected
modules, deferred home settings and primary-user home baseline imports there.
These typed core/deployment entries must stay excluded from optional discovery.

`modules/server/base.nix` is an **optional server-only feature** enabling fstrim,
SMART, journald retention, tools and password-required sudo. It must remain
separate from the explicit server baseline's boot, NetworkManager, timezone,
Nix resource limits and scheduled maintenance policies.

`modules/user-dev/ssh.nix` is **unconditional** in desktop and server Home Manager
catalogs. It installs sshfs and SSH settings for `*`, GitHub (fixed
`~/.ssh/id_ed25519_github` assumption), and the `server` alias. It defaults to the
`nixos-server` MagicDNS name and current home username, with optional identity
path override. Preserve both existing options and this personal behavior; making
it a universal generated-user default or adding an enable switch is separate work.

## Target layout and ownership

Use `.nixos.nix` / `.home.nix` for small single-file features and `nixos.nix` /
`home.nix` for complex directories. Retain helpers only behind their typed owner:
Neovim and Noctalia keep `config.nix`; tmux keeps `project-list.sh`; namespaces
keep their Nix/Python/migration helpers; deployment keeps its script and patches.
The complete tree includes those assets, not just discovered entries.

Colocate Niri system/home entries under `desktop/niri/`. Colocate Fish under
`dev/fish/`, consolidating its tiny home option/config split. Fish's system entry
remains desktop-only; its home entry remains desktop/server. Consolidate Kitty's
tiny split into `dev/kitty.home.nix`. Simplify single-file GNOME, Docker and
Starship directories. Colocate hardware/user screen recording using typed sibling
files. Keep desktop Syncthing and server Syncthing separate, with their distinct
policies. No option is renamed and no program-native source leaves `config/`.

## Reproduce the baseline and candidate evidence

Run from the integration checkout; keep output outside the repository. The
exporter accepts only empty public private-input maps and public users with no
SOPS secrets. Never remove those guards to publish private dumps.

```sh
baseline_dir=$(mktemp -d)
git archive pre-cleanup-history | tar -x -C "$baseline_dir"
python3 tests/module-equivalence/compare.py capture "$baseline_dir" /tmp/equivalence-baseline
# Stage new files first so Git flakes include them.
python3 tests/module-equivalence/compare.py capture "$PWD" /tmp/equivalence-candidate
python3 tests/module-equivalence/compare.py compare /tmp/equivalence-baseline /tmp/equivalence-candidate
# After all mapped entries have migrated:
python3 tests/module-equivalence/compare.py compare /tmp/equivalence-baseline /tmp/equivalence-candidate \
  --mapping docs/refactor/inventory.json
```

The capture uses the baseline's **fully assembled flake hosts**, not mock module
evaluations. `hosts.json` records recursive `my.*` option schemas (including
submodule fields, disabled features, types/defaults/read-only flags), values,
package names/versions/output and derivation identities, users/groups, system and
user unit text, firewall/nftables, privilege rules, PAM text, mounted destinations,
managed file metadata/source/text, activation DAG entries, SSH/Git/tmux and
Noctalia/Zen settings. All Home Manager users are included. `sources.json` hashes
tracked source bytes and executable bits, including assets referenced indirectly
by configuration adapters. `metadata.json` records the source root/revision;
archives must be tied to the exact `git archive` command above.

The exporter represents functions as opaque markers. It cannot prove function
semantics, arbitrary deferred module equivalence or behavior of every upstream
option. Deferred primary-user settings are checked through the resulting home
configuration; package predicates also need source review. The baseline source
manifest and unchanged package-source/lockfile checks complement this projection.

## Normalization and generated content review

Only the **exact flake source root** is replaced by `<repository>` at a path
boundary. No arbitrary store hash, package version, command, destination, UID,
mode or privilege is stripped. Lists stay ordered. Catalog mapping is explicit.
Source-to-target mappings do not authorize changed source bytes or executable bits.
Compare `sources.json` using the inventory's per-file mapping; only the documented
Fish/Kitty consolidations and necessary relative reference edits may differ.

A strict host comparison can fail after adding documentation or relocating source:
Nix embeds repository paths in generated scripts, changing their derivations and
then home generations/unit references. This is a **review gate**, not an allowed
blanket normalization. Diff `hosts.json`; for each changed derivation, build both
outputs non-activating, compare the relevant generated files and commands, and
record the exact old/new path substitution plus why it is safe. Keep package
name/version and all other arguments unchanged. Inspect source content with
`nix hash path PATH` or `diff -ru OLD NEW` after realization; compare modes,
symlink destinations and recursive file leaves as well as bytes. Do not replace
all `/nix/store/*` prefixes or accept a different derivation merely because its
name matches. Run adapter/source, host-profile, application and VPN tests too.

Managed-file contracts requiring this review include Fish recursive writable
snippet/function trees; Kitty's static PC source versus laptop font append;
Niri leaf mappings and selected workspace alias with generated Noctalia siblings;
Noctalia TOML/profile/template links and stale-settings activation; Neovim's
writable rsync copy preserving `lua/matugen.lua`; tmux/sesh command substitution;
and Zen's browser-owned profile state. Read the existing module/deployment guides
before each owning migration; never clean runtime files to match source.

See [baseline verification](verification.md) for actual results, hashes, private
access, derivation review and remaining checks. Each later ticket must preserve
this contract and update its evidence on the integration branch.
