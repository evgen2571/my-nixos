# Architecture

This repository defines three NixOS machines from one flake. NixOS owns
system configuration and services; Home Manager, integrated into each NixOS
configuration, owns user applications and dotfiles. Host profiles select
features, while reusable modules implement them.

## Configuration flow

```text
flake.nix (flake-parts; pinned inputs in flake.lock)
  └── flake/hosts.nix
        ├── lib/module-catalog.nix + lib/module-discovery.nix
        │     ├── desktop system + Home Manager module sets
        │     └── server system + Home Manager module sets
        ├── hosts/pc/configuration.nix + profile.nix
        ├── hosts/laptop/configuration.nix + profile.nix
        └── hosts/server/configuration.nix + profile.nix
              ├── modules/system-* / modules/desktops / modules/hardware
              ├── modules/server (server only)
              ├── modules/system-core/user.nix (primary-user adapter)
              │     └── home/evgen2571/home.nix + host Home Manager settings
              │           └── modules/user-*
              └── config/ (source dotfiles, wired by lib/config-paths.nix)
```

`flake/hosts.nix` constructs each `nixosConfigurations` output using
`nixpkgs.lib.nixosSystem`. It imports the host configuration, the appropriate
discovered module profile, Home Manager, and sops-nix. It also passes flake
inputs and `configPaths` to modules.

## Repository layout

| Location | Responsibility |
| --- | --- |
| `flake.nix`, `flake.lock`, `flake/` | Inputs, host outputs, development shell, formatting |
| `hosts/<host>/configuration.nix` | Hardware, identity, boot, and machine-specific settings |
| `hosts/<host>/profile.nix` | Enabled capabilities and host-specific options |
| `hosts/<host>/hardware-configuration.nix` | Filesystems and hardware detected for that machine |
| `lib/module-discovery.nix` | Find importable modules recursively |
| `lib/module-catalog.nix` | Assign discovered system/user modules to desktop/server profiles |
| `lib/config-paths.nix` | Centralize source paths and host-specific dotfile mappings |
| `modules/system-*`, `modules/desktops`, `modules/hardware` | NixOS services, packages, sessions, and hardware |
| `modules/server` | Server-only services and storage |
| `modules/user-*` | Home Manager applications, development tools, and desktop settings |
| `config/` | Fish, Neovim, Niri, Noctalia, Kitty, tmux-related, and other app configuration |
| `secrets/`, `keys/` | Encrypted SOPS documents and public key material |
| `packages/` | Locally packaged software, such as hide.me |
| `tests/`, `docs/` | Verification scripts and subsystem-specific documentation |

Module discovery treats a directory containing `default.nix` as one module.
Otherwise it finds `.nix` files recursively. The catalog assigns whole roots
to profiles; discovery does not automatically *enable* a feature. Options
typically use `my.system.*` for system facilities and `my.user.*` for
Home Manager. The `my.server.*` namespace is reserved for server features.

## Machines and profiles

| Flake output | Role | Configuration |
| --- | --- | --- |
| `nixos-pc` | Main graphical development workstation | Desktop profile, Niri/Noctalia, NVIDIA, development and AI tools |
| `nixos-lp` | Laptop development workstation | Desktop profile, Niri/Noctalia, laptop-specific hardware and services |
| `nixos-server` | Self-hosted services and storage | Server profile, SSH/Tailscale, Docker, Syncthing, `/srv` directories |

Both desktop hosts enable the `my.user.dev.workstation` bundle. It enables
the shared shell, editor, terminal workflow, toolchains, and related user
configuration; individual applications and language toolchains can still be
enabled per host. The server has a separate base system configuration and
enables only the user-side features it needs.

The primary-user adapter (`modules/system-core/user.nix`) creates the NixOS
user and connects `my.primaryUser.home.settings` to
`home-manager.users.<name>`. This keeps per-host user choices in
`profile.nix` without mixing Home Manager options into system modules.

## Ownership and lifecycle

- **NixOS:** boot, networking, security, services, hardware, system packages,
  filesystem mounts, and system trust roots.
- **Home Manager:** user packages, shell and Git configuration, editor setup,
  application settings, and XDG files.
- **Source dotfiles:** `config/` stores human-maintained files that modules
  link or copy to the appropriate runtime locations. The Neovim activation
  copies its configuration while preserving the generated Matugen theme.
- **Runtime state:** login sessions, application databases, generated caches,
  AI agent/Skillshare settings, credentials, and other writable state live
  outside the Nix store. They are not reconstructed solely from the flake.

The intended edit path is: change a reusable module or source config, select
it in a host profile if necessary, build the target host, and activate its
new generation. Do not put machine-specific defaults into a shared module.

## Networking

NetworkManager provides ordinary host networking; Tailscale connects the
machines for remote access. The server uses regular OpenSSH over Tailscale
with committed **public** authorized keys. Services explicitly control
which ports are exposed.

The desktop hosts also provide a separate `vpn` network namespace backed by
the hide.me client. Selected AI tools, including Codex and T3 Code, run
through that namespace with isolated DNS, routing, and egress checks rather
than moving the host's default network into the VPN. See
[VPN namespace design](docs/network-namespaces.md).

Currently both desktop hosts map `api.actline.test` and
`auth.actline.test` to `100.112.239.4` using `networking.extraHosts` and trust
the same Actline development root CA stored at
`hosts/pc/certs/actline-dev-rootCA.pem`. These mappings and trust settings
are still NixOS-managed and require activation after edits. Only the public
CA certificate belongs in Git; its signing private key does not.

## Secrets and trust

sops-nix uses a dedicated per-host age identity at
`/var/lib/sops-nix/key.txt`, configured by `modules/secrets.nix`. Hosts or
service modules declare the encrypted secret files they consume; decrypted
values become protected runtime paths, not Nix expressions or store files.

Commit SOPS-encrypted YAML, public recipients, and public SSH/CA certificates
only. Never commit private SSH/age/CA keys, session tokens, or decrypted
secrets. See [SOPS workflow](docs/sops.md).

## Server data and services

`modules/server/` configures the service foundation: storage, SSH, Docker,
and Syncthing. The server profile currently mounts its data filesystem at
`/srv/storage` and creates separate `/srv/compose`, `/srv/appdata`,
`/srv/shared`, `/srv/backups`, and `/srv/secrets` paths. Those sibling
directories are not automatically on the `/srv/storage` filesystem.

Persistent services must explicitly manage storage dependencies and backups;
Syncthing replication alone is not a backup. The host also configures
overnight suspend and RTC wake timers in `hosts/server/configuration.nix`.
See [server operations](docs/server.md), but treat the current Nix files as
authoritative if operational documentation lags behind.

## Developer workflow

```sh
nix develop
nix fmt
nix flake check
just build-pc                    # non-activating PC build
just build-lp                    # non-activating laptop build
just build-server                # non-activating server build
just switch-pc                   # activate on the matching machine
```

The `justfile` also provides `dry-*`, `boot-*`, and generic
`build`/`switch` targets. Perform a non-activating build before switching,
especially when changing authentication, storage, boot, or networking. NixOS
generations provide rollback points; runtime application state and secrets
need their own backup and recovery procedures.

## Design conventions

1. Keep the separation **host selection → reusable module → runtime state**.
2. Use a common module for shared behavior and `profile.nix` for host choices.
3. Prefer existing Home Manager/NixOS options over bespoke activation scripts;
   preserve application-managed state when scripts are unavoidable.
4. Never interpolate private credentials into the Nix store.
5. Add tests for behavior that can break activation or remote access, and keep
   subsystem-specific details in `docs/` rather than growing this overview.
