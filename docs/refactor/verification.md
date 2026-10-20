# Baseline verification and handoff

Evidence captured on 2026-10-20 from a `git archive` of exactly
`cb75bb68aaf0412f26488d63e4556e36c31193bd`. Initial integration HEAD matched that
revision and the working tree was clean. Original modules, application sources,
package/plugin locks, host selections and runtime state were not changed.

## Public comparison evidence

The [ordered catalog fixture](../../tests/module-equivalence/catalog-baseline.json)
contains 75 discovered entries. The [inventory](inventory.json) records all module
files, helper imports/assets and their typed targets; [option interfaces](option-interfaces.json)
records evaluated system and home schemas for all three hosts, including disabled
features and nested namespace/application options.

[`hosts-baseline.json.gz`](../../tests/module-equivalence/hosts-baseline.json.gz)
is the complete normalized **public** projection, compressed with gzip mtime 0.
The SHA-256 of its decompressed JSON is
`dc8421a6c1f8ae4aa870cb60db1de92ddd4b92670e48e0abb3c353c91949bc3c`.
Reproduce it using the capture procedure, or decompress it into `hosts.json`
alongside the catalog fixture as `catalog.json` for the comparator. Raw/private
host dumps and private build logs are not published.

Baseline source root was `/nix/store/67rx4izgk41y7agz4rn78ppj1sngmg02-source`.
Only that exact prefix at a path boundary was normalized. The integration
candidate's catalog inventories and normalized host projections matched exactly.
There were no unexplained package/derivation differences at this stage.

| Host | System `my.*` options (top-level option nodes) | Home `my.*` option nodes | System unit entries | Managed home files |
| --- | ---: | ---: | ---: | ---: |
| nixos-pc | 41 | 63 | 107 | 49 |
| nixos-lp | 41 | 63 | 118 | 49 |
| nixos-server | 42 | 29 | 104 | 9 |

Counts exclude nested fields under typed submodule options; those fields are
included recursively in the actual evidence. All three public Home Manager users
are `operator`. Personal identities come from the private input in production.

## Checks executed against the exact baseline

| Command / check | Result |
| --- | --- |
| `nix flake check path:BASELINE --no-write-lock-file` | Exit 0; all outputs and three host toplevels evaluated, but Nix reported **running 0 flake checks** |
| Same command with `--system x86_64-linux` | Same result; not treated as execution of checks |
| `nix build --impure --expr 'builtins.attrValues (builtins.getFlake "path:BASELINE").checks.x86_64-linux' --no-link` | Exit 0; all 12 registered check outputs present; existing valid store outputs reused |
| Registered checks | module-style, sesh-project-list, personal-metadata, migration-sources, niri-host-profiles, config-paths, shared-vpn-host-profiles, shared-vpn-systemd, shared-vpn-module, standalone-vpn-module, shared-vpn-recovery, shared-vpn-scripts |
| `nix run path:BASELINE#shared-vpn-test --no-write-lock-file` | Exit 0; disposable user/net/mount namespaces; simultaneous clients, IPv4/IPv6, DNS, fail-closed loss, recovery and unchanged host routes/resolver passed |
| `tests/neovim/run.sh` in isolated XDG config/data/cache/state with copied installed plugins | Exit 1; reproduced existing `Compact hover Markdown` assertion at `tests/neovim/smoke.lua:170`, after 11 named checks passed |
| `python3 tests/niri/window-titles.py` | Exit 0; 2 tests |
| `python3 tests/neovim/competitive.py` | Unavailable: `ModuleNotFoundError: No module named 'pynvim'`; no receiver/template session ran |

The VM check's retained build log reports `test script finished in 103.25s`.
A separate `--rebuild` run is recorded below so cached validation is distinguishable
from a fresh VM execution. The isolated Neovim plugins were copied from this
machine's installed set; this does not establish every installed plugin revision
against the lock. No live application, VPN route, service or host was activated.

## Private integration access

`gh repo view evgen2571/my-nixos-private --json visibility` confirmed **PRIVATE**
before cloning into a temporary local directory. Audit revision:
`70c2c843dba1ee03812bbf42ae5f85f89162d0a8`. An audit of its eight Nix source files
found no direct public `modules/` path references. The private checkout has no
flake lock and remains an input to this public build root. It was not changed.
No private keys, decrypted material or runtime credential files were inspected.

All three baseline non-activating private-backed builds exited 0:

```sh
nix build path:BASELINE#nixosConfigurations.nixos-pc.config.system.build.toplevel \
  --override-input private git+file:///PRIVATE_CHECKOUT?rev=70c2c843dba1ee03812bbf42ae5f85f89162d0a8 \
  --no-write-lock-file --no-link
# Repeated for nixos-lp and nixos-server.
```

This establishes build/audit access for subsequent tickets. Private generated
behavior must still be compared locally after each migration using this reviewed
revision pair; the public exporter deliberately refuses private material.
Build success cannot prove physical boot, login, graphical appearance, live VPN
egress, production secrets decryption, or runtime state compatibility.

## Integration validation and review

The registered `module-equivalence` check compares the full catalog fixture and
runs negative comparator tests for ordering, disabled-option loss, command/mode
changes, exact-root normalization and incomplete mapping. The public capture
is a separate integration procedure because it evaluates assembled hosts and
produces reviewer evidence rather than a sandbox mock.

Final results for clean archive `a00006e`:

- `nix flake check path:CLEAN --no-write-lock-file`: exit 0, including the new check.
- Explicit build of all 13 registered integration checks: exit 0.
- Fresh baseline `shared-vpn-systemd --rebuild --no-link --no-write-lock-file`:
  exit 0; distinct from the initially reused VM output.
- Clean-archive host capture versus baseline: strict comparison passed for all
  four ordered inventories and three hosts/users. Its decompressed host JSON is
  byte-identical to the committed gzip fixture.
- All three private-backed host builds from the clean integration archive also
  exited 0 using the same private revision; no activation occurred.
- Four comparator tests passed, including public-interface success/rejection
  cases. Nix formatting, documentation links, inventory coverage/uniqueness and
  all 230 baseline asset hashes passed; `git diff --check` passed.
- No diff to implementation modules, application sources, host/home definitions,
  package sources, `flake.lock` or plugin locks.
- Independent Standards review initially found an invalid exporter path element
  and negative tests that bypassed the comparator. Both were fixed and reviewed
  again: **0 remaining Standards findings**. Independent Spec review:
  **0 findings**. The corrected exporter was rerun from the clean archive.

The [target layout and mapping](target-tree.md) were subsequently reviewed and
approved on 2026-10-20 at the maintainer's request. Both Standards and Spec layout
reviews found no blockers. Fresh structural checks confirmed complete module/home
coverage, unique typed entry targets, explicit-assembly separation, the original
four inventory orders, and only the intended Fish/Kitty consolidations. No builds
or runtime checks were repeated for this documentation-only approval.


The integration draft is [PR #57](https://github.com/evgen2571/my-nixos/pull/57),
targeting `main`. Issue #50 records completed acceptance checkboxes and links to
these artifacts. The parent #49 and draft PR remain open for the remaining stages.
Nothing has been merged.


The integration branch was renamed to `refactor/feature-first-modules` at the
maintainer's request. GitHub automatically closed former draft #56 when its head
branch was renamed; draft #57 replaces it with the same commit history and evidence.
The next implementation stage is #51. Its native dependency #50 remains open in
the tracker even though its deliverables and layout review are complete.

## Typed discovery stage (#51)

Implemented from integration commit `6cdbad3` with every feature implementation,
host/profile/home assembly, application source, package selection and lockfile
unchanged. No module was relocated. The compatibility table is the ordered
75-entry projection of the approved inventory; it is not a newly sorted catalog.

| Verification | Result |
| --- | --- |
| `python3 tests/module-catalog/test_catalog.py` | 7 tests passed; initial typed-entry test failed against old catalog before implementation |
| Fixture coverage | Both typed naming forms, ignored helpers/assets, recursion beside `default.nix`, mixed legacy/typed migration, exact-once import, missing/duplicate/invalid-scope diagnostics, infrastructure exclusion, Fish scope eligibility, inventory coverage, and all 75 typed target slots |
| `nixfmt --check lib/module-catalog.nix lib/module-discovery.nix flake/verification.nix` | Passed |
| `deadnix --fail lib/module-catalog.nix lib/module-discovery.nix flake/verification.nix` | Passed |
| `python3 tests/module-equivalence/test_compare.py` | All 4 comparator tests passed |
| `nix flake check --no-write-lock-file` | Exit 0; hosts/check outputs evaluated, one new check executed, other valid outputs reused |
| `nix build --impure --expr 'builtins.attrValues (builtins.getFlake (toString ./.)).checks.x86_64-linux' --no-link` | Exit 0; all 14 registered outputs built/reused, including sandboxed catalog fixtures and existing catalog/host/VM/source/style checks |
| `python3 tests/module-equivalence/compare.py capture "$PWD" /tmp/issue51-evidence` | Exit 0; public fully assembled host/Home Manager evidence captured |
| `python3 tests/module-equivalence/compare.py compare /tmp/issue50-evidence-baseline /tmp/issue51-evidence` | Passed: all four ordered inventories and three host/Home Manager projections matched exactly |
| Complete catalog JSON versus `catalog-baseline.json` | Structurally identical, including ordered entries and scope/profile/root metadata |
| Three private-backed non-activating host builds | Exit 0 for PC, laptop and server, using the previously audited private revision `70c2c843dba1ee03812bbf42ae5f85f89162d0a8` after reconfirming PRIVATE visibility |
| `git diff --check` | Passed |

Private builds used all three `nixosConfigurations.<host>.config.system.build.toplevel`
attributes in one `nix build`, with the same local Git private override and
`--no-write-lock-file --no-link` as the baseline procedure above. Private inputs
and logs remained local. No arbitrary store-path normalization was added; public
host evidence matched with only the existing exact source-root normalization.
There were no unexplained derivation changes.

Independent Standards review: no actionable findings. Independent Spec review:
no implementation findings; its request to record completed validation is covered
here. The working tree began clean and changes are confined to discovery,
catalog/compatibility registrations, fixture checks and documentation.

The existing Neovim compact-hover failure and unavailable `pynvim` check recorded
above were not rerun: no application source changed. Existing VM outputs were
reused; no fresh VM or live namespace runtime test was needed for this catalog-only
change. Private host builds establish build compatibility, not a new private
behavior snapshot. Physical boot/login, GUI behavior, production decryption and
live VPN egress remain unverified. No live activation, runtime migration, route,
firewall or service change occurred.

For #52–#54, keep shared catalog/table ownership serialized as documented in
[module conventions](../reference/modules.md#temporary-legacy-compatibility).
The current `module-equivalence` flake assertion intentionally uses the untouched
legacy-path fixture; migration tickets must extend it to apply the approved
explicit mapping as paths move, without refreshing the original fixture.
Final #55 must remove legacy discovery and the temporary table while retaining
an explicit typed ordering contract. Draft PR #57 was neither replaced nor marked
ready; no PR was created and nothing was merged.

## Ordinary features and baselines (#52)

Stage begins at `631294b`, with clean working tree on
`refactor/feature-first-modules`. The [stage handoff](ordinary-features.md) and
[migration ledger](migrations.json) specify the exact 68 discovered entries and
four explicit baselines; the original #50 inventory and fixtures are unchanged.
The compatibility table/catalog/discovery are unchanged, preserving serialized
ownership and all original slots. Seven discovered entries and secrets/deployment
explicit assembly remain for #53/#54.

| Verification | Result |
| --- | --- |
| `python3 tests/module-catalog/test_catalog.py` | 7 tests passed; all four original orders/eligibilities remain mapped in place |
| `python3 tests/module-equivalence/test_compare.py` | 6 tests passed; partial migration and scoped module-reference tests first failed before implementation |
| `module-equivalence` Nix assertion | Initially failed against unmoved modules, passed after the 68 moves; compares complete catalog metadata and four ordered lists, plus explicit baseline existence/exclusion |
| Public assembled host capture and comparison | Passed against exact #50 baseline, using approved inventory plus explicit migration ledger |
| Raw public host diff | Exactly six source-module strings changed: configured Home Manager module and its default on each host; every other field identical |
| Package/derivation, source deployment and activation review | No changed package/output/derivation identities; Fish/Kitty file/source/text metadata, SSH, agent/Zen ownership, activation DAGs, system/user units and guard fields match |
| Source bytes and modes | All 230 mapped baseline assets present, executable bits preserved; 218 byte-identical, 9 reviewed #52 exceptions and 3 pre-existing #51 exceptions |
| #52 source exceptions | Fish's two constituents, Kitty's two constituents, primary-user module's relative home reference, three host import lists, new-host template import |
| `nixfmt --check` and `deadnix --fail` | Passed over all modules and the modified Nix equivalence assertion |
| `nix flake check --no-write-lock-file` | Exit 0; all three hosts and check outputs evaluated; three changed checks executed, remaining outputs reused |
| Explicit build of all registered checks | Exit 0; all 14 check outputs built/reused, including catalog, equivalence, module style, config-paths, host profiles, deployment/source, shell and namespace/VM checks |
| `python3 tests/niri/window-titles.py` | 2 tests passed |
| Three private-backed non-activating host builds | Exit 0 for PC/laptop/server, using PRIVATE repository revision `70c2c843dba1ee03812bbf42ae5f85f89162d0a8` |

The source audit compared all inventory assets, not just moved entries. The three
pre-existing #51 byte differences are `lib/module-catalog.nix`,
`lib/module-discovery.nix` and `flake/verification.nix`; these are unchanged in #52.
Every other implementation is a byte-identical move except the two approved
consolidations and the primary-user relative reference. No package-source,
lockfile, native application source, packaging source or host-profile selection
changed. Catalog counts remain desktop system/home 23/47, server 12/23.

The comparator retains exact source-root normalization. It additionally maps only
the two reviewed Home Manager module-reference fields through the approved
explicit inventory, as described in the stage handoff. No arbitrary store hash,
command, destination, option value or derivation is stripped.

Private visibility and the audited revision were reconfirmed before builds.
The same private input and public root were used without writing lockfiles.
A separate local-only private projection attempt failed already on the **baseline**:
the upstream Zen profile's `bookmarks.meta.doc` option has no defined value when
traversed by the generic projection. Consequently a full private behavior snapshot
comparison is unavailable; private build success is reported separately and does
not establish private behavioral equality. The public exporter and all its
private-material guards remain unchanged. No private snapshots/values were
published, no decrypted material or key files were read, and the private checkout
was not changed.

The previously recorded Neovim compact-hover failure and missing `pynvim` check
were not rerun: their owning modules and native sources remain for #53. Existing
VM outputs were reused; no new live namespace exercise was needed for these
byte-identical source moves. GUI appearance, physical boot/login, storage mounts,
production decryption and real VPN egress remain manual checks. No activation,
service restart, runtime migration, route/firewall change or data deletion occurred.
