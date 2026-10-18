# Architecture

This document is the durable architecture contract for `my-nixos`: what owns each kind of configuration, how modules reach hosts, and which behaviors must be preserved. For actionable task entry points use [docs/task-routing.md](docs/task-routing.md); for module implementation patterns use [docs/modules.md](docs/modules.md). [AGENTS.md](AGENTS.md) defines the agent workflow, not the system design.

The Nix code is authoritative about current implementation. When documentation and code disagree, inspect the code and amend documentation as part of a scoped fix rather than reproducing an outdated assumption.

## Configuration flow

```text
flake.nix (flake-parts; pinned inputs in flake.lock)
  └─ flake/hosts.nix: mkHost using nixpkgs.lib.nixosSystem
      ├─ lib/module-catalog.nix → lib/module-discovery.nix
      │   ├─ desktop: system modules + shared Home Manager modules
      │   └─ server:  system modules + shared Home Manager modules
      ├─ hosts/pc/configuration.nix      + profile.nix + secrets.nix
      ├─ hosts/laptop/configuration.nix  + profile.nix + secrets.nix
      └─ hosts/server/configuration.nix  + profile.nix + secrets.nix
          ├─ modules/system-core/{common,server,user}.nix (explicit host imports)
          ├─ modules/secrets.nix (explicit flake import)
          ├─ discovered modules: NixOS/system-* and Home Manager/user-*
          └─ modules/system-core/user.nix (primary-user adapter)
              └─ home/default.nix and per-host HM settings
                  └─ config/ source dotfiles via lib/config-paths.nix
```

`my-nixos` remains the sole build/deployment root. Its tracked empty
`templates/private` input exports optional `nixosModules` and `secretFiles` maps.
`flake/hosts.nix` selects `none`, `local` or `private` explicitly before imports;
only private mode adds narrow modules through `extraModules`. Existing outputs
require private material and protected identities for deployment; public evaluation
is deliberately separate. See [installation](docs/installation.md).

`flake/hosts.nix` assembles the outputs with Home Manager and sops-nix NixOS modules, passes flake inputs and `configPaths` as special arguments, and assigns either the `desktop` or `server` discovered module profile. The Home Manager modules are supplied through `home-manager.sharedModules`; host user choices are supplied separately.

**Availability is not enablement.** `lib/module-catalog.nix` chooses which module roots are visible to a profile. `lib/module-discovery.nix` finds importable modules. Hosts then enable capabilities via options, generally from `profile.nix`. A directory with `default.nix` is a single discovered module; its other files must be imported by that entry point. See [module conventions](docs/modules.md).

## Ownership boundaries

| Layer | Owns | Does not own |
| --- | --- | --- |
| `flake.nix`, `flake/` | Inputs, output assembly, formatter, checks, development shell | Host-specific feature toggles |
| `hosts/<host>/configuration.nix` | Host identity, boot, hardware, base imports and exceptional machine settings | Generic app/service implementations |
| `hosts/<host>/profile.nix`, `hosts/common/` | Shared desktop feature selection and explicit host-specific option values | Reusable package and service logic |
| `lib/module-catalog.nix` | Imported module roots for desktop/server | Application enable flags |
| `modules/system-*`, `modules/desktops/`, `modules/hardware/`, `modules/server/` | System packages, services, hardware, security, desktop/session plumbing | User application dotfile contents |
| `modules/user-*` | Home Manager packages, application integration, user services and XDG mappings | Host boot and global network policy |
| `config/` | Source dotfiles, editor/plugin config, window manager rules, browser profile definitions | OS service ownership or secrets |
| `secrets/`, `keys/`, optional private input | User-owned local ciphertext, public keys; private input owns maintainer ciphertext/narrow overrides | Plaintext authentication material |
| `tests/` | Automated behavior checks and smoke tests | Deployment authorization |

Custom options normally follow `my.system.*`, `my.user.*`, `my.desktop.*`, `my.hardware.*`, or `my.server.*`. `modules/system-core/user.nix` bridges `my.primaryUser.home.settings` to the selected `home-manager.users` entry, keeping user feature selection in the host profile.

Application configuration may cross two layers deliberately. For example, the NixOS Niri module provisions the session and portals, while the Home Manager Niri module maps files in `config/niri/` into the user's XDG configuration. The source dotfiles are **not** a replacement for the module that installs them.

## Hosts and profiles

| Output | Role | Selection |
| --- | --- | --- |
| `nixos-pc` | Main Niri/Noctalia development desktop | `hosts/pc/profile.nix`; desktop catalog |
| `nixos-lp` | Niri/Noctalia laptop | `hosts/laptop/profile.nix`; desktop catalog |
| `nixos-server` | Services, storage and server-only VPN gateway | `hosts/server/profile.nix`; server catalog |

The two desktop profiles explicitly import `hosts/common/desktop.nix` for identical feature selections. Narrow private desktop modules supply development aliases and CA trust. Host differences and VPN selections remain local. These shared profiles are outside module discovery and retain ordinary declaration priority; see the [selection inventory](docs/desktop-host-defaults.md).

The two desktop hosts enable `my.user.dev.workstation`, a Home Manager bundle that defaults shared terminal, shell, editor and tool features on. Language options and individual applications remain host-selectable. The server has a smaller Home Manager module profile and a separate base system configuration.

Hardware-specific `configuration.nix` files and `hardware-configuration.nix` files should not be flattened into a generic host module just to reduce apparent duplication. Share behavior only when its meaning and deployment lifecycle are genuinely the same.

## State ownership and activation

Configuration source and live application state are not interchangeable:

1. **Declarative OS state:** NixOS options configure system services, security, boot, network and installed software.
2. **Declarative user integration:** Home Manager manages user packages, application wiring, session variables and many XDG files.
3. **Source configuration:** `config/` is version-controlled input; `lib/config-paths.nix` maps sources to runtime paths and selects machine-specific variants (for example Niri workspace files).
4. **Mutable runtime state:** Generated colors, accounts/login sessions, application databases, writable agent resources, cached data and certain application-owned files are intentionally outside immutable Nix-store management.

Neovim is a special case: `modules/user-dev/neovim/config.nix` copies `config/nvim/` through a Home Manager activation entry using `rsync`, excluding generated `lua/matugen.lua`. Replacing this with a whole-directory symlink would change the expected state model. Noctalia also combines declarative source config with generated runtime theme/settings. Zen profiles are selected per host; not all browser data is declaratively reproduced. Skillshare agent resources, MCP definitions and settings remain writable at runtime; see [docs/skillshare.md](docs/skillshare.md).

NixOS system generations provide system rollback, not a backup of mutable application data or secrets. Activation scripts must be safe on repeated runs and must not erase state they do not own.

## Network and security invariants

Ordinary host networking is managed independently of the isolated VPN path. Tailscale connects the machines. The selected-agent route is:

```text
Codex or explicit orca-vpn
  → desktop vpn namespace (shared0)
  → host Tailscale transport
  → server vpn namespace (shared0)
  → Hide.me tunnel (hm0)
  → Internet
```

The **server alone** hosts the Hide.me provider and restricted underlay. Desktop namespaces are clients; they have no local provider or fallback to host networking. Selected applications fail closed when provider, tunnel, DNS or egress validation fails. Normal desktop traffic, host SSH and Docker retain normal networking. The launcher is restricted to registered applications and is not a general privileged shell.

VPN changes must preserve independent namespace firewalling, IPv4/IPv6 routing, isolated DNS, scoped privileges, safe service lifecycle and recovery controls. Read [docs/shared-vpn-gateway.md](docs/shared-vpn-gateway.md) and [docs/network-namespaces.md](docs/network-namespaces.md). The earlier implementation plan is archived in `docs/archive/`; operational code, host observations, and current runbooks take precedence.

sops-nix decrypts committed encrypted documents into protected runtime secret paths. Host-specific age identities live outside the repository under `/var/lib/sops-nix/key.txt`. Private keys and access tokens must not appear in unencrypted Git files, Nix expressions, derivation arguments, or public documentation. Public SSH/WireGuard/CA keys may be versioned. See [docs/sops.md](docs/sops.md).

Only PC and laptop select the private development aliases and CA trust through their private host overrides. The certificate is stored at `certs/actline-dev-rootCA.pem` at the private repository root, and referenced from its `hosts/{pc,laptop}.nix` modules. The server does not import this feature. These settings remain NixOS-managed and require activation to change.

## Server data boundaries

`modules/server/` owns SSH, Docker foundation, storage and Syncthing. The server profile mounts the data filesystem at `/srv/storage` and configures `/srv/compose`, `/srv/appdata`, `/srv/shared`, `/srv/backups` and `/srv/secrets` separately; those paths are **not implicitly on the storage mount**. Services must explicitly handle storage dependencies and backups. Syncthing replication is not a substitute for backups.

Server sleep/wake logic is in `hosts/server/configuration.nix` and is sensitive to the gateway role. See [docs/server.md](docs/server.md) before modifying lifecycle or storage.

## Design decisions and non-goals

- **Host choices remain declarative at the host boundary.** Modules implement features; profiles select them. This avoids hidden host-name branching in reusable modules.
- **The catalog is the import boundary.** A new file under an already-discovered root normally needs no new path bookkeeping. New roots require an intentional catalog change.
- **Use native NixOS/Home Manager options first.** Custom activation scripts are justified for specific mutable-state constraints, not as a default package manager.
- **Runtime state is not necessarily reproducible.** Do not claim the flake reconstructs credentials, sessions or all application databases.
- **Isolation and access recovery take precedence over simplification.** VPN and server code may carry deliberate complexity to preserve security and operational safety.
- **Documentation has a single owner per question.** This file explains architecture; [docs/modules.md](docs/modules.md) explains module mechanics; [docs/task-routing.md](docs/task-routing.md) locates files; `docs/` runbooks describe operational workflows; [AGENTS.md](AGENTS.md) directs coding agents.

## Validation and deployment

Use non-activating verification while developing:

```sh
nix develop
nix fmt
nix flake check --no-build
just build-pc
just build-lp
just build-server
```

`nix flake check --no-build` evaluates but does not execute registered tests. Run `nix flake check` for the full flake checks when appropriate. `flake/verification.nix` currently registers network-namespace checks; `tests/neovim/run.sh` is a separate Neovim smoke entry point. Review the changed diff after formatting and build the affected hosts; changes to shared modules may require all three. `justfile` also defines non-activating `dry-*` and explicitly activating `switch-*`/`boot-*` recipes.

Deploy on the matching real host only with explicit authorization. Changes to networking, access control, authentication, boot, storage or secrets need a concrete rollback/recovery plan, not just a successful evaluation.
