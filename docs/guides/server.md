# Server operations: nixos-server

This runbook describes the **configuration in Git**, not a live health report. Before changing or deploying the server, inspect the running generation, actual mount points, current services and Tailscale reachability on the host. For VPN design and safety, read [shared VPN gateway](shared-vpn-gateway.md); agents should start with [agents/networking.md](../../.agents/networking.md) for network changes.

## Ownership

| Concern | Source |
| --- | --- |
| Host identity, hardware, nightly suspend/wake policy | `hosts/server/configuration.nix`, `hosts/server/hardware-configuration.nix` |
| Enabled features, storage device, VPN gateway/peers | `hosts/server/profile.nix` |
| Base NixOS boot and resource tuning | `modules/system-core/server.nix` |
| Services (SSH, Docker, storage, Syncthing) | `modules/server/` |
| Tailscale | `modules/system-services/tailscale.nix` |
| Namespace gateway and related systemd units | `modules/system-services/network-namespaces/` |
| Runtime credentials | `hosts/server/secrets.nix`, `modules/secrets.nix`, [SOPS guide](../reference/secrets.md) |
| Client SSH aliases | `modules/user-dev/ssh.nix` and host profiles |

The flake output is `nixos-server`; the private override retains the existing normal user. `modules/server/` is imported only into the server catalog profile. Some system service modules are imported by both server and desktop profiles, but their features are enabled per host.

## Current declarative state

- The repository contains a real generated `hosts/server/hardware-configuration.nix`, not a placeholder. Do not regenerate or replace it without checking the target hardware and mounted filesystems.
- `modules/system-core/server.nix` configures UEFI/systemd-boot, NetworkManager, Nix settings and scheduled garbage collection.
- `hosts/server/profile.nix` enables SSH over Tailscale, Docker, storage, Syncthing, Tailscale and the server-role `vpn` namespace.
- The storage device is configured via a stable `/dev/disk/by-uuid/...` path and mounted at **`/srv/storage`**; confirm that device and its actual mount on the host before making storage changes.
- `hosts/server/configuration.nix` defines a 01:00 night-suspend timer and a 06:00 wake-capable timer. **The suspend timer is disabled while the VPN role is `gateway`**; the morning wake timer remains configured. Do not assume suspend is disabled if the role changes.
- `system.stateVersion` remains `26.05`; do not change it during ordinary upgrades.

These statements describe the Nix files and not whether a particular configuration generation is currently active or whether a service is healthy.

## SSH and access recovery

The server uses normal OpenSSH, **not** Tailscale SSH. `my.server.ssh.openOnLan = false` configures port 22 for `tailscale0`, not a general host firewall opening. Root login and password-based SSH authentication are disabled. The private server override supplies the existing primary account and its SSH public-key associations. Public defaults authorize no personal keys.

Desktop clients use host-specific private identities through a Home Manager SSH alias. After confirming tailnet access, `ssh server` is the intended client workflow. For a key change, keep a working session and console open, build the server without activating it, deploy only with authorization, and verify a **second** SSH session before closing the first. Removing the last working key can lock out administration.

Tailscale is enabled declaratively but first-time device enrollment is a separate manual process. If a new installation is genuinely required, verify enrollment and SSH on a console before depending on remote access.

## Storage and backup boundaries

The storage module creates the following directory layout:

| Path | Purpose | Backing filesystem |
| --- | --- | --- |
| `/srv/storage` | Dedicated ext4 storage mount | Device set in the server profile |
| `/srv/compose` | Docker Compose projects | Not implicitly on `/srv/storage` |
| `/srv/appdata` | Application databases / persistent state | Not implicitly on `/srv/storage` |
| `/srv/shared` | Shared service data | Not implicitly on `/srv/storage` |
| `/srv/backups` | Backup location | Not implicitly on `/srv/storage` |
| `/srv/secrets` | Restricted optional runtime secret directory | Not implicitly on `/srv/storage` |

`modules/server/storage.nix` manages the `server-data` group, permissions, tmpfiles rules and the `/srv/storage` mount. These sibling paths can reside on the root filesystem despite their names. **Check `findmnt` before choosing data placement, retention policy or backup destinations.** Replication is not backup; ensure backup copies have an appropriate failure domain.

Useful non-mutating host inspection:

```sh
findmnt -T /
findmnt -T /srv/storage
findmnt -T /srv/appdata
findmnt -T /srv/backups
lsblk -f
df -h / /srv/storage
systemctl status srv-storage.mount --no-pager
```

The Syncthing module asserts that storage is enabled and a stable device path is configured. It uses directories under `/srv/appdata/syncthing/` and requires the `/srv/storage` mount for its systemd unit. Its GUI is configured on port 8384; firewall exposure is explicitly scoped to `tailscale0`, with sync traffic on port 22000. Folders/devices are not forcibly overridden by Nix; check actual Syncthing UI credentials, folders and runtime state before edits.

## Docker and service operations

`modules/server/docker-host.nix` enables the daemon, weekly image pruning with a seven-day age filter, JSON file logs with 10 MB × 5 rotation and `live-restore`. The main server user belongs to the `docker` group, which effectively grants root-equivalent access. Compose files belong under `/srv/compose`; data locations must be chosen and backed up explicitly.

Inspect without modifying state:

```sh
systemctl --failed
systemctl status sshd tailscaled docker syncthing --no-pager
tailscale status
docker info
ss -lntup
journalctl -b -p warning --no-pager
```

For gateway troubleshooting, prefer [the VPN runbook](shared-vpn-gateway.md) and the namespace health checks over restarting services speculatively. Do not change server suspend/reboot behavior while it is serving desktop VPN clients without coordinated approval.

## Secrets and trust

SOPS-encrypted documents under `secrets/` and public recipients/keys may be versioned. Protected runtime paths are consumed by configured services. Never store plaintext access tokens, private age/SSH/WireGuard keys or decrypted secrets in Git, derivations, issue discussions or logs. `/srv/secrets` is only a filesystem interface if a service explicitly needs it.

See [SOPS workflow](../reference/secrets.md) for recipient rotation and provisioning. Missing runtime credentials are an operational deployment condition, **not** permission to invent test or production secret values.

## Build and release safety

From a reviewed checkout, first validate without changing the server:

```sh
nix flake check --no-build
nix build --no-link .#nixosConfigurations.nixos-server.config.system.build.toplevel
```

Run full `nix flake check` when the registered checks and build environment are available. Non-activating success does not prove remote access, mounted storage or real VPN egress. For shared-module modifications, evaluate/build other impacted hosts too.

Activation is **not part of normal code review**. Before an explicitly approved deployment, ensure a working console or independent rollback mechanism, a second viable SSH route, and verified storage/backup status. Evaluate server generation changes from a host-networked session, not a VPN-isolated agent. An explicitly authorized operator can use `sudo nixos-rebuild test --flake .#nixos-server` then persist with `switch` only after health and recovery checks.

A boot-menu generation rollback or `nixos-rebuild --rollback` can restore NixOS system configuration. Neither reverts mutable application data nor automatically undoes firewall/mask state maintained outside the generation. Follow the VPN-specific rollback considerations before modifying those units.

## First installation and migration history

This server has already received a hardware-specific NixOS configuration in Git. First-install procedures (generating hardware config, Tailscale enrollment, creating storage filesystems) are **not** routine maintenance steps and must not be blindly repeated on a provisioned host.

Previous [first-install server notes](../archive/server-initial-setup-notes.md) and the [shared-VPN implementation plan](../archive/shared-vpn-gateway-implementation-plan.md) are archived for provenance, not operational truth. Check current host status and the active runbook before interpreting historical acceptance checkboxes.
