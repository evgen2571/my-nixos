# Server: nixos-server

## 1. Server architecture

- Host configuration: `hosts/server/`
- Reusable server modules: `modules/server/`
- Flake output: `nixos-server`
- Server modules are imported **only** by the server profile via discovery
- PC (`nixos-pc`) and laptop (`nixos-lp`) remain in the same repository and
  are unaffected by server module imports

## 2. Human-only values

These values must **not** be guessed or invented. They require access to the
actual server hardware or administrator provisioned secrets:

- Real `hardware-configuration.nix` — generated on the target machine
- Storage disk UUID / stable device path — read from `lsblk -f` / `sudo blkid`
- Private SSH keys — generated on the client, only the `.pub` file goes in Git
- User passwords — set interactively or via a hash, never committed
- Hermes agent environment — `/var/lib/hermes/env`
- WireGuard VPNBook configs — `/etc/wireguard/vpnbook/`
- Tailscale enrollment — run `sudo tailscale up` interactively, or provision
  an authentication key separately outside Git.

## 3. SSH authorized keys

Public keys live in `keys/`:

```text
keys/
├── README.md
└── operator-pc.pub
```

They are declared in `hosts/server/configuration.nix`:

```nix
my.primaryUser.authorizedKeyFiles = [
  ../../keys/operator-pc.pub
];
```

### Adding a key

1. Copy only the `.pub` file into `keys/` with a descriptive name.
2. Add its relative path to `authorizedKeyFiles`.
3. Run formatting and a build.
4. Keep the current SSH session open.
5. Test a second session with the new key.
6. Only then close the original session.

### Revoking a key

1. Remove its path from `authorizedKeyFiles`.
2. Rebuild.
3. Confirm another key still works.
4. Verify the revoked key no longer authenticates.

> Public keys are not private credentials, but the comment field (e.g.
> `operator-pc`) may reveal a device name or email address. Choose
> appropriately.

## 4. Hardware configuration

Generate the real file on the target machine:

```bash
sudo nixos-generate-config --show-hardware-config \
  > hosts/server/hardware-configuration.nix
```

Replace the existing placeholder at `hosts/server/hardware-configuration.nix`.

The generated file will produce a `hardware-configuration.nix` appropriate for
the target hardware. However, it does **not** automatically validate or change
the bootloader policy, because bootloader settings are defined separately in
`modules/system-core/server.nix`.

### Boot mode and bootloader

The current server profile enables systemd-boot and assumes UEFI firmware:

```nix
boot.loader.systemd-boot.enable = true;
boot.loader.efi.canTouchEfiVariables = true;
```

Before installation, verify that the target server boots in UEFI mode and that
systemd-boot is appropriate.

Replacing `hosts/server/hardware-configuration.nix` does not automatically
validate the bootloader policy because bootloader settings are defined in the
server system module.

For legacy BIOS systems, unusual firmware, encrypted boot layouts, or another
bootloader, review and change the bootloader configuration before activation.

Review the generated filesystem declarations carefully. Do **not** copy
hardware config from the PC or laptop machines.

After replacement, verify with a non-activating build:

```bash
nix build .#nixosConfigurations.nixos-server.config.system.build.toplevel
```

## 5. Storage disk

Find the storage disk:

```bash
lsblk -f
sudo blkid
```

Set a **stable** device path such as:

```
/dev/disk/by-uuid/...
/dev/disk/by-label/...
/dev/disk/by-id/...
```

Do **not** use fragile paths like `/dev/sda1` or `/dev/sdb1`.

Configure it in `hosts/server/profile.nix`:

```nix
my.server.storage.device = "/dev/disk/by-label/MY-NIXOS-HISTORICAL-241DBE07-REPLACE-ME";
```

### Why Syncthing is initially disabled

`my.server.syncthing.enable` is `false` by default because the storage device
is `null`. Enabling Syncthing without a dedicated storage disk would cause it
to write synchronized data to the root filesystem, which is dangerous.

Set `my.server.storage.device` first, then enable Syncthing.

## 6. Server paths

| Path | Owner | Permissions | Purpose |
|------|-------|-------------|---------|
| `/srv/compose` | operator:server-data | 0750 | Docker Compose project files |
| `/srv/appdata` | operator:server-data | 2770 | Persistent app state |
| `/srv/storage` | root:server-data | 2770 | Mount point for data disk |
| `/srv/shared` | operator:server-data | 2770 | Shared data between services |
| `/srv/backups` | operator:server-data | 2770 | Backup destination |
| `/srv/secrets` | root:root | 0700 | Runtime secrets (provisioned externally) |

The `2` prefix in `2770` sets the SGID bit so newly created subdirectories
inherit the group.

## 7. Docker

- Enabled via `my.server.dockerHost.enable`
- Compose projects belong in `/srv/compose`
- Persistent application state belongs in `/srv/appdata`
- Secrets must **never** go in Git — use `/srv/secrets` or an external
  secret manager
- Docker logs are size-limited (10 MB per file, 5 files max)
- Automatic pruning runs weekly, retaining images younger than 7 days
- `live-restore` is enabled so containers keep running during daemon restarts

> **WARNING:** Membership in the `docker` group is effectively equivalent to
> root-level control of the server. Only add trusted users.

## 8. Syncthing

- Initially disabled — enable only after `my.server.storage.device` is set
- State directory: `/srv/appdata/syncthing/`
- Synchronized folders should be created under `/srv/storage`
- The GUI is exposed **only** through Tailscale firewall rules (port 8384)
- The GUI still needs its own username and password configured before it is
  considered secure
- No folders are created declaratively by default; configure them through the
  GUI or REST API

## 9. Tailscale and firewall

- `tailscale0` is **not** globally trusted
- The shared Tailscale module exposes `my.system.services.tailscale.openFirewall`
  (default `false`) which opens the UDP transport port on the general host firewall
- Only the server enables `openFirewall`:

  ```nix
  my.system.services.tailscale = {
    enable = true;
    openFirewall = true;
  };
  ```

- PC and laptop retain the default `false`
- This opens Tailscale's UDP transport port through the general host firewall
- This does **not** globally trust `tailscale0`
- Application services must still open the specific ports they need on `tailscale0`
- SSH starts with `openOnLan = true` for bootstrap access
- After confirming that OpenSSH works through the server's Tailscale IP, the administrator may set:

  ```nix
  my.server.ssh.openOnLan = false;
  ```

- Keep one SSH session open while testing this change
- Upstream router firewall rules still apply regardless of these settings

## 10. Runtime secrets

The following paths contain secrets provisioned separately and are **not**
committed to Git:

| Path | Contents |
|------|----------|
| `/var/lib/hermes/env` | Hermes agent environment variables |
| `/etc/wireguard/vpnbook/` | VPNBook WireGuard `.conf` files |
| `/srv/secrets/` | Application-level secrets |

These must be created manually on the server. Service failures are expected
when required runtime secrets are absent.

## 11. Safe build procedure

```bash
nix fmt
git diff --check
nix flake check
nix build .#nixosConfigurations.nixos-server.config.system.build.toplevel
```

> The server build will **deliberately fail** while the hardware placeholder
> with `assertion = false` is in place. This is expected.

After real hardware configuration exists:

```bash
sudo nixos-rebuild dry-build --flake .#nixos-server
```

Before activating, ensure you have a working login available.

Activation commands (do not run during this setup):

```bash
sudo nixos-rebuild test --flake .#nixos-server
sudo nixos-rebuild switch --flake .#nixos-server
```

## 12. Verification after activation

```bash
systemctl --failed
systemctl status sshd
systemctl status tailscaled
systemctl status docker
tailscale status
docker info
ss -lntup
journalctl -b -p warning
```

When Syncthing is enabled:

```bash
systemctl status syncthing
```

## 13. Rollback

```bash
sudo nixos-rebuild switch --rollback
```

If remote access is broken and local console is available, select an older
generation from the systemd-boot menu at boot time.
