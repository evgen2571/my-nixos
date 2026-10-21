# Complex desktop and development features (#53)

Spec: [#53](https://github.com/evgen2571/my-nixos/issues/53). Stage starts at
`pre-cleanup-history`; functional baseline remains `pre-cleanup-history`.
Continue on `refactor/feature-first-modules`, retaining draft PR #57.

## Mapping and ownership

The cumulative [migration ledger](migrations.json) adds six entries to #52's 68.
Join original paths with [inventory.json](inventory.json) for exact source bytes,
modes, eligibility and asset mappings. All nine assigned files move byte-for-byte.

| Original entry / supporting asset | Approved target |
| --- | --- |
| `modules/desktops/niri/default.nix` | `modules/desktop/niri/nixos.nix` |
| `modules/user-desktop/niri/config.nix` | `modules/desktop/niri/home.nix` |
| `modules/desktops/noctalia-greeter.nix` | `modules/desktop/noctalia-greeter.nixos.nix` |
| `modules/user-desktop/noctalia/default.nix` | `modules/desktop/noctalia/home.nix` |
| `modules/user-desktop/noctalia/config.nix` | `modules/desktop/noctalia/config.nix` |
| `modules/user-dev/neovim/default.nix` | `modules/dev/neovim/home.nix` |
| `modules/user-dev/neovim/config.nix` | `modules/dev/neovim/config.nix` |
| `modules/user-dev/tmux/default.nix` | `modules/dev/tmux/home.nix` |
| `modules/user-dev/tmux/project-list.sh` | `modules/dev/tmux/project-list.sh` |

Niri's colocated NixOS/Home Manager owners retain separate enable options.
Noctalia shell and greeter have explicit separate typed owners, retaining upstream
imports in Home Manager and NixOS respectively. Noctalia and Neovim `config.nix`
helpers remain private explicit imports; tmux owns `project-list.sh`.
No shared catalog/discovery/compatibility change is necessary: the frozen table
substitutes typed paths in their existing ordered slots. Legacy support remains
for #54's namespace entry; secrets/deployment explicit assembly is also unmigrated.
Final #55 removes the temporary bridge while preserving order.

All native trees under `config/`, package selections/pins, special arguments,
host selections and templates remain unchanged. tmux's sesh source remains at
the same relative depth; its executable substitution and keybindings are intact.
The sesh flake check and current documentation now reference the typed locations.

## State and generated content

Neovim retains the writable activation-time rsync copy, Matugen exclusion and
existing symlink transition; no application state is removed by this migration.
Niri retains per-leaf deployment, host-selected workspace aliases and generated
Noctalia siblings. Noctalia retains TOML sources, shared/host-specific files,
templates, generated themes/runtime settings and stale-settings activation.
Greeter source/package, settings, PAM and scoped appearance-sync authorization
are byte-identical. No activation, restart, route/firewall change or runtime
migration is performed. Existing rollback/recovery guidance remains in the
[greeter guide](../operations/noctalia-greeter.md#deploy-and-recover).

## Verification

Use the original [comparison contract](README.md), then:

```sh
python3 tests/module-equivalence/compare.py capture "$PWD" /tmp/issue53-evidence
python3 tests/module-equivalence/compare.py compare \
  /tmp/issue50-evidence-baseline /tmp/issue53-evidence \
  --mapping docs/refactor/inventory.json --migrations docs/refactor/migrations.json
```

Exact results and unavailable manual/private checks are recorded in
[verification.md](verification.md#complex-desktop-and-development-features-53).
