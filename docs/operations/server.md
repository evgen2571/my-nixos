# Server

`nixos-server` runs Docker, Syncthing, storage and the shared VPN gateway. Inspect
the running generation and mounts before maintenance; Git describes the intended
configuration, not current host health.

## Access and status

The server uses ordinary OpenSSH over `tailscale0`, not Tailscale SSH. Root and
password-based SSH login are disabled. Private host settings supply the account
and authorized public keys. After checking tailnet connectivity, use `ssh server`
from the configured desktop client.

From a normal host terminal:

```sh
readlink -f /run/current-system
systemctl --failed
systemctl status sshd tailscaled docker syncthing --no-pager
tailscale status
vpn-status --verbose
ss -lntup
journalctl -b -p warning --no-pager
```

Tailscale enrollment is a manual first-install step. Keep console access until
SSH works. For key changes, keep the original session open and verify a second
login before closing it.

## Storage and backups

| Path | Purpose | Backing filesystem |
| --- | --- | --- |
| `/srv/storage` | Dedicated ext4 storage | Stable device selected in the server profile |
| `/srv/compose` | Compose projects | Check on the host |
| `/srv/appdata` | Persistent application data | Check on the host |
| `/srv/shared` | Shared service data | Check on the host |
| `/srv/backups` | Backup destination | Check on the host |
| `/srv/secrets` | Optional restricted runtime interface | Check on the host |

Sibling `/srv/*` paths are not automatically on `/srv/storage`. Confirm mounts
before placing data or choosing backup destinations:

```sh
findmnt -T /
findmnt -T /srv/storage
findmnt -T /srv/appdata
findmnt -T /srv/backups
findmnt -T /srv/compose
lsblk -f
df -h / /srv/storage
systemctl status srv-storage.mount --no-pager
```

The storage module manages permissions and the `server-data` group. Syncthing
requires the storage mount, but keeps its configuration and database under
`/srv/appdata/syncthing/`. Its GUI uses TCP 8384; sync uses TCP/UDP 22000, exposed
only on `tailscale0`. Nix does not forcibly replace runtime folders/devices.
Inspect those and GUI credentials before changes. Replication is not backup;
verify application-consistent restores and a separate failure domain.

## Docker and gateway maintenance

Compose projects belong under `/srv/compose`; choose and back up their data paths
explicitly. The Docker group grants effectively root-level access. The daemon
uses live restore, weekly image pruning with a seven-day age filter, and JSON
logs rotated at 10 MB with five files. `docker info` is a read-only inspection.

The gateway role disables the 01:00 night-suspend timer. The 06:00 wake-capable
timer remains configured. Changing the role can change suspend behavior. Check:

```sh
systemctl is-enabled server-night-suspend.timer
systemctl status server-morning-wake.timer --no-pager
```

Coordinate reboot, suspend and VPN work with both desktop clients. Use
[VPN diagnosis](vpn.md) before restarting services. Resume detection cannot wake
a powered-down gateway.

## Change and recover

Use the reviewed private input and non-activating commands in
[deployment](deployment.md#build-without-activation). A build cannot verify SSH,
mounts or real provider egress. Activation needs independent console/host SSH,
verified backups and explicit operator approval.

[Rollback](deployment.md#rollback-and-recovery) restores system configuration,
not databases, Tailscale enrollment or persistent VPN masks. Never regenerate
hardware configuration, create filesystems or replace identities as routine
maintenance. Keep `system.stateVersion` unchanged during ordinary upgrades.

| Change | Source |
| --- | --- |
| Hardware, boot and wake policy | [host configuration](../../hosts/server/configuration.nix), [hardware](../../hosts/server/hardware-configuration.nix) |
| Features and storage selection | [host profile](../../hosts/server/profile.nix) |
| SSH, Docker, storage, Syncthing | [server modules](../../modules/server/) |
| Base system | [server core](../../modules/core/server-baseline.nixos.nix) |
| VPN | [namespace modules](../../modules/system-services/network-namespaces/) |
| Credentials | [secrets guide](secrets.md) |
