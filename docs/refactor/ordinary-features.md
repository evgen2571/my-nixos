# Ordinary features and baselines (#52)

Spec: [#52](https://github.com/evgen2571/my-nixos/issues/52).
Stage starts at `631294b`; functional baseline remains
`cb75bb68aaf0412f26488d63e4556e36c31193bd`. Continue on
`refactor/feature-first-modules` and retain draft PR #57. No activation or merge.

## Exact mapping and boundaries

The [migration ledger](migrations.json) lists the 68 migrated discovered entries
and four explicit baselines by original path. Join each path to
[inventory.json](inventory.json)'s `entries`/`explicit` and `assets` for its exact
approved target and every constituent file. This ledger is cumulative for the
remaining integration stages; the original inventory and baseline fixtures remain
unchanged. Only the original path slots are replaced; nothing is sorted anew.

| Assigned group | Target / ownership |
| --- | --- |
| Six AI tools | `modules/ai/*.home.nix`; mutable agent resources stay runtime-owned |
| Ordinary user/system applications | `modules/apps/*.{home,nixos}.nix`; Zen retains browser-owned profile state |
| GNOME, OpenTabletDriver, X server, recording | `modules/desktop/`; recording system/home entries stay independent |
| Bluetooth and NVIDIA | `modules/hardware/*.nixos.nix` |
| Five server features | `modules/server/*.nixos.nix`; optional base remains distinct |
| Six ordinary shared services | `modules/services/*.nixos.nix`; desktop and server availability retained |
| Docker, Fish, ordinary developer tools/bundles/languages | `modules/dev/`; system desktop-only, home desktop/server |
| Dolphin, Thunar, Yazi | `modules/files/`; existing separate system/home scopes |
| Desktop/server baselines, primary-user adapter/home baseline | `modules/core/`; explicit assembly, outside optional discovery |

Seven discovered entries remain legacy: Niri system/home, Noctalia shell/greeter,
Neovim and tmux belong to #53; network namespaces belongs to #54. Secrets and
deployment explicit assembly and their assets also belong to #54. Their sources,
helpers, tests, script paths and compatibility registrations are unchanged.
Program-native `config/`, packaging, package sources and all lockfiles stay put.

No shared discovery/catalog/compatibility edit was necessary. The frozen table
substitutes exactly these 68 typed entries into the original slots. Catalog
fixtures still exercise both layouts. Final #55 must remove legacy support while
retaining the explicit ordering contract.

## Consolidations, references and personal policy

Fish's former `default.nix` option and `config.nix` implementation now share
`dev/fish/home.nix`; its NixOS implementation is `dev/fish/nixos.nix`. Kitty's
former two files share `dev/kitty.home.nix`. Both preserve enable guards and the
same `configPaths` adapters. Fish's main file and recursive writable snippet and
function trees, and Kitty's PC source/laptop font-size append, retain their
existing destinations and ownership. GNOME, Docker and Starship become single
files. No other implementation is rewritten.

All three host configurations and the new-host template import the renamed core
entries. The primary-user adapter points to its colocated `primary-user.home.nix`.
Current application, customization, server and architecture guides use the new
paths. Historical baseline paths in the comparison contract, original inventory,
compatibility table and synthetic legacy fixtures intentionally remain.

The desktop baseline retains its boot/audio/fonts/packages, automatic Nix resource
policy and maintenance timers. The separate server baseline retains its one-job,
two-core policy, weekly idle-priority GC and disabled automatic optimisation.
Optional server base still gates fstrim, SMART, journald retention and tools.
The Home Manager baseline keeps its state version, Cargo session path and release
check policy. Host selections and workstation `mkDefault` priorities are unchanged.

`dev/ssh.home.nix` remains unconditional on desktop/server. Its GitHub key path
`~/.ssh/id_ed25519_github`, `server` alias, default `nixos-server` MagicDNS host
and current-home-username assumption are personal policy preserved from baseline.
Both existing override options remain; no SSH enable switch or generated-host
policy was introduced.

## Comparison procedure

Use the original baseline capture from the [comparison contract](README.md).
Stage new files before capturing the current Git flake, then run:

```sh
python3 tests/module-equivalence/compare.py capture "$PWD" /tmp/issue52-evidence
python3 tests/module-equivalence/compare.py compare \
  /tmp/issue50-evidence-baseline /tmp/issue52-evidence \
  --mapping docs/refactor/inventory.json --migrations docs/refactor/migrations.json
```

`module-equivalence` compares complete catalog metadata and four ordered lists
against the original fixture with only ledger-declared mappings. The command
above compares all three assembled public host/Home Manager projections.

The raw host diff contains exactly six changed strings: `homeWiring.module` and
`options.primaryUser.home.module.default` on each host change from
`<repository>/home/default.nix` to
`<repository>/modules/core/primary-user.home.nix`. The new home source has identical
bytes/mode. The comparator translates only these two fields using the approved
explicit mapping. It does not translate command strings, arbitrary source paths,
store hashes, derivations, destinations, permissions or other option defaults.
Regression tests reject changed commands even when they equal the moved path.
All other captured host fields match exactly; no package/derivation changed.

## Verification

Final validation results and remaining limitations are recorded in
[verification.md](verification.md#ordinary-features-and-baselines-52).
