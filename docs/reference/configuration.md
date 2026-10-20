# Find and check a configuration change

Start with the matching row, then read the owning module and affected host
profile. Application guides explain how the configured behavior works.

| Change | Start here |
| --- | --- |
| Enable or disable a feature | `hosts/<host>/profile.nix`; shared desktops use `hosts/common/desktop.nix` |
| Add an app or service | Nearest `modules/apps/`, `modules/dev/`, or `modules/services/` sibling; [module conventions](modules.md) |
| Boot or hardware | `hosts/<host>/configuration.nix`, `hardware-configuration.nix` |
| Flake inputs or host assembly | `flake.nix`, `flake/hosts.nix` |
| Stable/unstable or external package selections | `lib/package-sources.nix`; [package sources](modules.md#package-sources) |
| Module discovery | `lib/module-catalog.nix`, `lib/module-discovery.nix` |
| Fish, tmux, Kitty | `config/fish/`, `modules/user-dev/`, [Kitty](../apps/kitty.md) |
| Neovim mappings or plugins | `config/nvim/lua/core/`, `lua/plugins/`; [Neovim](../apps/neovim.md) |
| Niri shortcuts or layout | `config/niri/sub/binds.kdl`, `layout.kdl`, `input.kdl`; [Niri](../apps/niri.md) |
| Niri window placement | `config/niri/sub/rules/`, host workspace sources |
| Noctalia shell or themes | `config/noctalia/`, `modules/desktop/noctalia/`; [Noctalia](../apps/noctalia.md) |
| Greeter or login | `modules/desktop/noctalia-greeter.nixos.nix`; [greeter](../operations/noctalia-greeter.md) |
| Zen spaces and pins | `config/zen/`, `modules/apps/zen-browser.home.nix`; [Zen](../apps/zen-browser.md) |
| Agent tools | `modules/ai/`; [Skillshare](../apps/skillshare.md), [CodeGraph](../apps/codegraph.md) |
| VPN, DNS isolation, launchers | `modules/system-services/network-namespaces/`; [VPN](../operations/vpn.md), [namespace implementation](../operations/network-namespaces.md) |
| Source modes or deployment preflight | `lib/secret-source.nix`, `modules/deployment/`; [secrets](../operations/secrets.md) |
| Server storage, SSH, Docker, Syncthing | `modules/server/`, `hosts/server/profile.nix`; [server](../operations/server.md) |
| Checks | `flake/verification.nix`, matching `tests/` subtree |

## Choose verification by impact

| Scope | Checks |
| --- | --- |
| Documentation | Relative links, referenced paths, `git diff --check` |
| One application or host | Formatting and targeted evaluation; non-activating affected-host build where available |
| Shared modules | Evaluate all affected hosts; build when needed to verify generated artifacts |
| Neovim | Inspect `tests/neovim/run.sh`, then relevant isolated smoke checks; manually check appearance |
| Niri/Noctalia | Validate complete deployed include trees, including generated files; manually check each affected host |
| VPN/systemd/security | Dedicated `tests/network-namespaces/` checks, affected-host builds, recovery plan |
| Boot, storage, authentication | Non-activating host build and a practical recovery path |

```sh
nix flake check --no-build --no-write-lock-file
nix flake check --no-write-lock-file
nix build .#nixosConfigurations.nixos-pc.config.system.build.toplevel --no-link
```

The first command evaluates checks; the second executes registered checks.
Production host builds also need the explicit [private override](../operations/deployment.md).
`just build-pc`, `build-lp`, and `build-server` are conveniences; see
[Just setup](../operations/deployment.md#everyday-rebuilds-with-just).
Review formatter changes before committing: `nix fmt` can
touch files outside the task.

Build success cannot prove graphical behavior, physical boot, login, or real VPN
egress. State which checks ran and what still needs manual verification. Live
activation is a separate step.
