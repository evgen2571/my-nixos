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

Final integrated validation after the comparator/ledger changes passed again:
`nix flake check --no-write-lock-file` exited 0 (two changed checks executed;
others reused), and the explicit build of all 14 registered check outputs exited
0. All 232 relative documentation links/anchors and both staged/unstaged
`git diff --check` passed. Stale-path review found only documented historical
references, frozen compatibility registrations and synthetic legacy fixtures.

Independent reviews of `631294b...132d5c1`: **Standards: 0 actionable findings;
Spec: 0 findings**. The Spec reviewer independently reran all six comparator and
seven catalog tests successfully. Implementation commit: `132d5c1`.
Issue #52's ten acceptance checkboxes and four Agent Brief checkboxes are updated
with this stage's delivery. Integration remains on the existing draft PR #57;
no ready-for-review transition, merge or activation is authorized by this stage.

## Complex desktop and development features (#53)

Stage begins at `5506933` on `refactor/feature-first-modules` with a clean tree.
The [stage handoff](complex-features.md) records all nine file mappings, helper
ownership and writable-state boundaries. The cumulative ledger now records
74 discovered migrations; namespaces and secrets/deployment remain for #54.
Shared catalog, discovery, compatibility registrations and frozen inventory are
unchanged. No coordination edit to those shared files was needed.

| Verification | Result |
| --- | --- |
| Existing catalog-equivalence assertion, red/green | Failed with the six added ledger entries before moves (old Niri path versus typed target); passed after moves |
| `python3 tests/module-catalog/test_catalog.py` | 7 tests passed |
| `python3 tests/module-equivalence/test_compare.py` | 6 tests passed |
| Original-baseline public capture/comparison with approved mapping and ledger | Passed for all four ordered catalogs and three assembled hosts/Home Manager users |
| Comparison with #52 public evidence | Identical complete host projections; no new package/derivation, managed-file, generated text, native option, permissions, activation, PAM, privilege or service differences |
| Nine assigned feature files | All byte-identical to original inventory hashes, executable modes preserved; old entry files absent |
| Complete asset audit | All 230 mapped assets present with unchanged executable modes; 218 byte-identical; same 12 paths differed in #51/#52; this stage additionally updates only the sesh check path within flake/verification.nix |
| `nixfmt --check`, `deadnix --fail` | Passed for moved modules and flake verification; deadnix also checked all modules and package sources |
| tmux/sesh shellcheck and project-list script tests | Passed; flake check uses the moved private script |
| `python3 tests/niri/window-titles.py` | 2 tests passed |
| Complete Niri trees, `niri validate` | Passed for pc, laptop and default workspace profiles, using evaluated per-leaf adapters and copied complete generated Noctalia includes from the existing disposable test fixture |
| `tests/neovim/run.sh`, isolated XDG roots and copied installed dependencies | Same baseline failure: Compact hover Markdown assertion at smoke.lua:170, after the same 11 checks passed |
| `python3 tests/neovim/competitive.py`, same isolated XDG roots | Same baseline limitation: missing pynvim; no receiver/template session ran |
| `nix flake check --no-write-lock-file` | Exit 0; two changed checks executed, other valid outputs reused |
| Explicit build of all 14 registered check outputs | Exit 0; includes config-paths, Niri host profiles, sesh, catalog/equivalence, source/deployment, style and namespace/VM outputs |
| Three private-backed non-activating host builds | Exit 0 for PC/laptop/server with the same audited private revision; logs kept local |

Only the exact repository source root and the two previously approved #52 home
module-reference fields are normalized, as specified in the comparison contract.
No arbitrary store hash, derivation, source content, command or authorization
rule is stripped. No new derivation differences require content normalization.
The unchanged package selections, native sources and exact deployed projections
cover generated tmux/sesh configuration, Noctalia source/shared/profile/template
files, Niri leaves and Neovim activation's writable copy/Matugen exclusion.

Private repository visibility was reconfirmed PRIVATE before using revision
`70c2c843dba1ee03812bbf42ae5f85f89162d0a8`. The private checkout was unchanged;
no secrets or keys were inspected. The #52 baseline private projection limitation
(unsupported upstream Zen option traversal) still prevents a complete private
behavior snapshot; successful private builds are separate evidence. No private
snapshots were published. Disposable Neovim dependencies came from the existing
baseline test copy of installed plugins, not a fresh lockfile installation.

Niri validation includes fixture-generated themes and proves syntax/includes,
not fresh theme generation or GUI appearance. Existing VM outputs were reused;
no fresh VM execution or live VPN exercise ran. Physical login/keyring unlock,
appearance sync, manual UI behavior, boot, production decryption and real VPN
egress remain unverified. No activation, restart, runtime migration, route/firewall
change or application-data deletion occurred.

Independent reviews of `5506933...3ea5cc2`: **Standards: 0 findings; Spec: 0
findings**. The Spec reviewer independently reran the original-baseline
comparison and seven catalog tests successfully. Final committed-source capture
and comparison passed again; final integrated flake check and explicit build of
all 14 registered checks exited 0. All 239 relative documentation links/anchors
and `git diff --check` passed. Active-reference search found no stale feature
paths outside the intentional historical inventory/compatibility/ledger/handoff.
Issue #53's nine acceptance checkboxes and four Agent Brief checkboxes are
updated. Implementation commit: `3ea5cc2`. The existing integration PR #57
remains draft; no merge or ready-for-review transition occurred.

## VPN, secrets and deployment infrastructure (#54)

Stage begins at clean `4b23d57` on `refactor/feature-first-modules`.
The [infrastructure handoff](infrastructure.md) records the complete mapping,
explicit assembly and recovery/state boundaries. All 75 discovered entries and
six explicit entries now have their approved targets. Frozen inventory, catalog,
discovery, compatibility registrations, package selections and lockfile are
unchanged in this stage; the legacy bridge remains for #55.

| Verification | Result |
| --- | --- |
| Catalog-equivalence assertion, red/green | Failed on missing mapped explicit infrastructure before moves; passed after moves |
| `python3 tests/module-catalog/test_catalog.py` | 7 tests passed, including explicit infrastructure exclusion and legacy compatibility |
| `python3 tests/module-equivalence/test_compare.py` | 6 tests passed |
| `python3 tests/network-namespaces/recovery.py` | 42 tests passed |
| Original-baseline capture/comparison with approved mapping and cumulative ledger | All four ordered inventories and three complete public host/Home Manager projections matched |
| Comparison with #53 public capture | Complete host projections byte-identical; no new package/derivation or generated-content differences |
| Source/mode audit | All 230 mapped assets present with unchanged executable modes; 216 original hashes match; namespace's ten files and deployment entry byte-identical |
| `nixfmt --check`, `deadnix --fail`, namespace/migration `shellcheck`, `git diff --check` | Passed |
| `nix flake check --no-write-lock-file` | Exit 0; four changed checks built, other valid outputs reused |
| Explicit build of all 14 registered check outputs | Exit 0, including namespace standalone/shared/host/VM, source/deployment, catalog/equivalence, style and application checks |
| `nix run .#shared-vpn-test --no-write-lock-file` | Exit 0; fresh disposable user/net/mount namespace isolation, simultaneous clients, IPv4/IPv6, DNS and fail-closed recovery checks |
| `nix build .#checks.x86_64-linux.shared-vpn-systemd --no-write-lock-file --no-link --rebuild` | Exit 0; fresh three-machine VM execution, test script 105.56 seconds; lifecycle, DNS, bounded recovery, rollback, old-generation reboot and persistent desktop masks |
| Standalone source/deployment harness with pinned age/SOPS tools | Exit 0; none/local builds, disposable key-only first-login VM, unsafe/missing/wrong identity refusals, missing encrypted field and first-login configuration refusals; lock unchanged |
| Three non-activating private-backed host builds | Exit 0 for PC/laptop/server, using the audited private revision |
| Targeted private-backed infrastructure comparison against exact original baseline | All three host projections matched after exact repository-root substitution; no values published |

The 14 source-byte differences against the original inventory consist of the
already documented earlier-stage changes plus the relocated secrets module's
two relative source references. `flake/hosts.nix` now explicitly selects the
approved secrets/deployment paths; `flake/verification.nix` repairs namespace
sandbox and script references. All ten namespace files, four deployment script/
patch assets and the deployment module retain their bytes and executable modes.
Namespace package calls retain their depth and targets. The full generated host
projection has no new derivation differences needing content exceptions. Existing
normalization remains restricted to exact source roots and the two previously
approved primary-user module-reference fields; no store hashes, commands,
privileges or generated content are broadly stripped.

Private visibility was reconfirmed **PRIVATE** before auditing/building revision
`70c2c843dba1ee03812bbf42ae5f85f89162d0a8`. Its eight Nix files have no direct old
public-module imports; no private source changes are required for that revision.
The audit does not cover unavailable consumers. No keys, decrypted credentials
or runtime tokens were inspected. Builds still originate only from this public
repository, with the same explicit local Git private override and no lock write.

A local-only comparison evaluated baseline and candidate `nixosConfigurations`
with that private override. The projection covered complete namespace settings
and app registrations (including executable derivations), SOPS secret metadata,
age settings, account/group definitions, all system/user units and `/etc` files,
firewall/nftables/resolver settings, sudo/wrappers/polkit, system source checks,
activation/pre-switch/builder commands, guarded install/rebuild derivations,
Home Manager shared wiring and Codex/Orca options/user units. It compared recursive
values strictly, encoding derivations as name/output/derivation paths and replacing
only each exact public source root. No private snapshots were written or published;
only comparison results and error/differing-field paths stayed in protected local
logs. Initial overbroad projections hit unset upstream `sops.defaultSopsFile`
and `users.ldap.base` on the baseline; the focused projection selects the actual
infrastructure settings instead. The older whole-private option-schema/Zen
projection limitation remains; this targeted comparison does not claim complete
private Home Manager option equivalence.

No live activation, restart, route/firewall change, secret edit, runtime recovery
or migration occurred. Real provider egress, production decryption, physical
boot/login and hardware suspend/resume remain manual checks; disposable fixtures
and non-activating builds do not establish those results. Unrelated Neovim/UI
checks were not repeated; their baseline limitations remain as recorded above.

The standalone harness initially exited 127 after its successful first-login VM
because the host shell lacked `age-keygen`. Rerunning with pinned tools passed:

```sh
nix shell --impure --expr 'let f = builtins.getFlake (toString ./.); p = f.inputs.nixpkgs.legacyPackages.x86_64-linux; in [ p.age p.sops ]' \
  --command bash tests/migration/standalone.sh
```
