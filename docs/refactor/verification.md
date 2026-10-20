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

Final check/review results are appended here before publication. A draft PR does
not approve the target layout on the maintainer's behalf or authorize migration,
merge or deployment; remaining tickets consume this artifact after review.
