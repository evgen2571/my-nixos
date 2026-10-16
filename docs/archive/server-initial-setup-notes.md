# Archived: first-install server notes

> Historical snapshot of the former `nixos-server` setup guide. Its placeholder hardware configuration, disabled Syncthing, and no-suspend statements are **obsolete** relative to current Nix files. It is preserved for provenance, not as a routine maintenance or installation script. Refer to [current server operations](../server.md) for authoritative configuration ownership and safety checks.

---

# Server: nixos-server

## 1. Server architecture

- Host configuration: `hosts/server/`
- Reusable server modules: `modules/server/`
- Flake output: `nixos-server`
- Server modules are imported **only** by the server profile via discovery
- PC (`nixos-pc`) and laptop (`nixos-lp`) remain in the same repository and
  are unaffected by server module imports

## 2. Fixed identity

- Hostname: `nixos-server`
- Username: `server`
- The server is kept online; there is no scheduled suspend timer in the server configuration.

## 3. Human-only values

These values must **not** be guessed or invented. They require access to the
actual server hardware or administrator provisioned secrets:

- Real `hardware-configuration.nix` — generated on the target machine
- Storage disk UUID / stable device path — read from `lsblk -f` / `sudo blkid`
- Private SSH keys — generated on the client, only the `.pub` file goes in Git
- User passwords — set interactively or stored as a SOPS-encrypted hash
- Hermes agent environment — `/var/lib/hermes/env`
- WireGuard VPNBook configs — `/etc/wireguard/vpnbook/`
- Tailscale enrollment — run `sudo tailscale up` interactively, or provision
  an authentication key separately outside Git.

## 4. SSH through Tailscale

The server uses ordinary OpenSSH over its Tailscale address.

The separate Tailscale SSH feature is not enabled.

Tailscale provides the private network path.
OpenSSH performs public-key authentication.

## 5. SSH authorized keys

Public keys live in `keys/`:

```text
keys/
├── README.md
├── users/
│   └── evgen2571/
│       ├── pc.pub       (main PC)
│       └── laptop.pub   (laptop)
└── hosts/               (reserved for SSH host identity/trust public keys)
```

- `users/evgen2571/pc.pub` belongs to the main PC.
- `users/evgen2571/laptop.pub` belongs to the laptop.
- Only public keys are committed. Private keys remain on their respective
  devices.
- Both keys authenticate as user `server`.
- To revoke one device, remove only its public-key path from
  `authorizedKeyFiles`.

They are declared in `hosts/server/configuration.nix`:

```nix
my.primaryUser.authorizedKeyFiles = [
  ../../keys/users/evgen2571/pc.pub
  ../../keys/users/evgen2571/laptop.pub
];
```

### Adding a key

1. Copy only the `.pub` file into `keys/users/<user>/` with a descriptive name.
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
> `evgen2571-pc`) may reveal a device name or email address. Choose
> appropriately.

## 6. Hardware configuration

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

## 7. Storage disk

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
my.server.storage.device = "/dev/disk/by-uuid/YOUR-UUID-HERE";
```

### Why Syncthing is initially disabled

`my.server.syncthing.enable` is `false` by default because the storage device
is `null`. Enabling Syncthing without a dedicated storage disk would cause it
to write synchronized data to the root filesystem, which is dangerous.

Set `my.server.storage.device` first, then enable Syncthing.

## 8. Server paths

| Path | Owner | Permissions | Purpose |
|------|-------|-------------|---------|
| `/srv/compose` | server:server-data | 0750 | Docker Compose project files |
| `/srv/appdata` | server:server-data | 2770 | Persistent app state |
| `/srv/storage` | root:server-data | 2770 | Mount point for data disk |
| `/srv/shared` | server:server-data | 2770 | Shared data between services |
| `/srv/backups` | server:server-data | 2770 | Backup destination |
| `/srv/secrets` | root:root | 0700 | Optional runtime interface for services that require a secrets directory |

The `2` prefix in `2770` sets the SGID bit so newly created subdirectories
inherit the group.

## 9. Docker

- Enabled via `my.server.dockerHost.enable`
- Compose projects belong in `/srv/compose`
- Persistent application state belongs in `/srv/appdata`
- Plaintext secrets and private age keys must **never** go in Git. Encrypted
  SOPS files are intended to be committed; expose their decrypted runtime paths
  directly to services where possible. Use `/srv/secrets` only when a service
  specifically requires a directory-based runtime interface.
- Docker logs are size-limited (10 MB per file, 5 files max)
- Automatic pruning runs weekly, retaining images younger than 7 days
- `live-restore` is enabled so containers keep running during daemon restarts

> **WARNING:** Membership in the `docker` group is effectively equivalent to
> root-level control of the server. Only add trusted users.

## 10. Syncthing

- Initially disabled — enable only after `my.server.storage.device` is set
- State directory: `/srv/appdata/syncthing/`
- Synchronized folders should be created under `/srv/storage`
- The GUI is exposed **only** through Tailscale firewall rules (port 8384)
- The GUI still needs its own username and password configured before it is
  considered secure
- No folders are created declaratively by default; configure them through the
  GUI or REST API

## 11. Tailscale and firewall

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
- SSH port 22 is allowed on `tailscale0` but not on any general firewall interface
- The server uses `openOnLan = false` to restrict SSH to the Tailscale network
- Upstream router firewall rules still apply regardless of these settings

## 12. Manual first-boot Tailscale enrollment

After installing NixOS on the server, the following steps must be performed
from the local/provider console:

1. Boot the installed NixOS server.
2. Open the local/provider console.
3. Log in using the available local/root console method.
4. Run `sudo tailscale up`.
5. `tailscale up` prints an authentication URL. Open that URL in a browser
   and approve the new machine `nixos-server`.
6. Run `tailscale status` to confirm the machine is connected.
7. Run `tailscale ip -4` to obtain the server's Tailscale IPv4 address.
8. From the main PC, test connectivity:
   ```bash
   tailscale ping SERVER_TAILSCALE_IP
   ssh server@SERVER_TAILSCALE_IP
   ```
9. From the laptop, test connectivity:
   ```bash
   tailscale ping SERVER_TAILSCALE_IP
   ssh server@SERVER_TAILSCALE_IP
   ```
10. Keep the local/provider console open until both SSH connections succeed.

Do not configure a Tailscale authentication key. The enrollment is manual.

Do not expect SSH to be available before Tailscale enrollment.

### Declarative SSH client alias

PC and laptop configure the same alias through Home Manager:

```bash
ssh server
```

The alias resolves `nixos-server` through Tailscale MagicDNS and selects a
different private key on each client:

- PC: `~/.ssh/id_ed25519_nixos_pc`
- laptop: `~/.ssh/id_ed25519_nixos_lp`

This avoids hard-coding a Tailscale `100.x` address in the SSH configuration.
The separate Tailscale SSH feature is still not required; OpenSSH performs the
authentication.

## 13. Runtime secrets

Plaintext secrets and private age identities are never committed. SOPS-encrypted
files under `secrets/` and their public age recipients are intended to be
committed; sops-nix decrypts declared secrets into protected runtime paths.
See [the SOPS workflow](../sops.md) for host key bootstrap, editing, declaration,
and rotation.

Some existing services still use separately provisioned runtime interfaces:

| Path | Contents |
|------|----------|
| `/var/lib/hermes/env` | Hermes agent environment variables |
| `/etc/wireguard/vpnbook/` | VPNBook WireGuard `.conf` files |
| `/srv/secrets/` | Optional directory for applications that cannot consume a sops-nix runtime path directly |

These paths are not encrypted repository files. Populate them manually or from
a declared sops-nix secret according to the consuming service. Service failures
are expected when required runtime secrets are absent.

## 14. Safe build procedure

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

## 15. Verification after activation

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

## 16. Rollback

```bash
sudo nixos-rebuild switch --rollback
```

If remote access is broken and local console is available, select an older
generation from the systemd-boot menu at boot time.
