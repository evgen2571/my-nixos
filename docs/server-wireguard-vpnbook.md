# NixOS server with VPNBook WireGuard failover

This repo contains a starter server host:

```text
nixosConfigurations.nixos-server
hosts/server/configuration.nix
hosts/server/profile.nix
modules/system-services/vpnbook-wireguard-failover.nix
```

The goal is a small NixOS server that starts a WireGuard VPN on boot and automatically switches to the next VPNBook configuration if the current one stops working.

## Important VPNBook constraints

VPNBook currently provides WireGuard configs from:

```text
https://www.vpnbook.com/freevpn/wireguard-vpn
```

Important constraints from VPNBook's WireGuard page:

- WireGuard configs auto-expire after 7 days.
- Each config should be used on one device at a time.
- You must generate/download configs from the website; do not commit them to this repo.

Current WireGuard-capable VPNBook hosts seen on their Free VPN page:

```text
us16.vpnbook.com
us178.vpnbook.com
ca149.vpnbook.com
ca196.vpnbook.com
uk205.vpnbook.com
uk68.vpnbook.com
de20.vpnbook.com
de220.vpnbook.com
fr200.vpnbook.com
fr2311.vpnbook.com
```

Use the website to generate actual `.conf` files because VPNBook generates unique client keys/configs.

## Why configs are not stored in Git

Generated WireGuard configs contain private keys. Treat them as secrets.

Store them on the server only:

```text
/etc/wireguard/vpnbook/*.conf
```

Recommended permissions:

```bash
sudo install -d -m 700 /etc/wireguard/vpnbook
sudo install -m 600 ~/Downloads/vpnbook-*.conf /etc/wireguard/vpnbook/
```

## How failover works

The module installs a command:

```bash
vpnbook-wg
```

and systemd units:

```text
vpnbook-wireguard.service
vpnbook-wireguard-check.service
vpnbook-wireguard-check.timer
```

Behavior:

1. On boot, `vpnbook-wireguard.service` starts.
2. It picks the remembered active config from `/var/lib/vpnbook-wireguard/active.conf`, or the first `.conf` from `/etc/wireguard/vpnbook`.
3. It copies that config to `/run/vpnbook-wireguard/vpnbook0.conf` and runs `wg-quick up`.
4. The timer runs a health check every minute.
5. If the health check fails through interface `vpnbook0`, it switches to the next config file.

Manual commands:

```bash
sudo vpnbook-wg status
sudo vpnbook-wg check
sudo vpnbook-wg switch
sudo vpnbook-wg stop
sudo systemctl restart vpnbook-wireguard.service
sudo systemctl status vpnbook-wireguard.service
sudo systemctl status vpnbook-wireguard-check.timer
journalctl -u vpnbook-wireguard.service -u vpnbook-wireguard-check.service -f
```

## Setup flow for the new server

### 1. Install NixOS on the server/VM

During installation, generate the hardware config:

```bash
sudo nixos-generate-config
```

Then copy the generated hardware config into this repo as:

```text
hosts/server/hardware-configuration.nix
```

The file currently in the repo is only a placeholder so the host exists before installation.

### 2. Copy or clone this repo on the server

Example:

```bash
git clone <your-repo-url> ~/my-nixos
cd ~/my-nixos
```

If using a local copy instead of GitHub, copy the directory to the server with `rsync`.

### 3. Review host settings

Check:

```text
hosts/server/configuration.nix
hosts/server/profile.nix
```

Current server defaults:

- hostname: `nixos-server`
- SSH enabled
- root SSH login disabled
- password SSH login disabled
- Tailscale enabled as the management network
- firewall trusts `tailscale0`
- UDP 41641 opened for direct Tailscale connections
- user: `evgen2571`
- nixos-pc SSH public key authorized for `evgen2571`
- Hermes Agent official NixOS module enabled
- WireGuard VPNBook failover enabled
- VPN configs expected in `/etc/wireguard/vpnbook`

Before switching, make sure your SSH key is configured for the user. Because password login is disabled, do not lock yourself out.

If this is the first install and you do not yet have keys configured, temporarily set:

```nix
services.openssh.settings.PasswordAuthentication = true;
```

Then disable it after key login works.

### 4. Bring Tailscale up before relying on VPNBook

Tailscale should be your management/recovery path. After the first switch, authenticate the machine:

```bash
sudo tailscale up --ssh --hostname=nixos-server
```

Then verify from your laptop/PC:

```bash
tailscale status
ssh evgen2571@nixos-server
```

If MagicDNS is disabled in your tailnet, use the Tailscale IP instead:

```bash
tailscale ip -4 nixos-server
ssh evgen2571@100.x.y.z
```

Do this before enabling or testing VPNBook WireGuard, because a full-tunnel VPN can change the server's default route. Tailscale routes to `100.64.0.0/10` should usually keep tailnet SSH working, but you still want provider console/recovery access available for the first test.

### 5. Set up Hermes Agent on the server

Hermes Agent is installed through its official Nix flake/NixOS module, not through `curl | bash`.

The repo adds this flake input:

```nix
hermes-agent.url = "github:NousResearch/hermes-agent";
```

and imports:

```nix
hermes-agent.nixosModules.default
```

The server profile enables:

```nix
services.hermes-agent = {
  enable = true;
  addToSystemPackages = true;
  environmentFiles = [ "/var/lib/hermes/env" ];
  settings.model.default = "openai/gpt-5.4";
};
```

Create the runtime environment file on the server; it must not be committed to Git:

```bash
sudo install -d -m 700 -o hermes -g hermes /var/lib/hermes
printf 'OPENROUTER_API_KEY=sk-or-your-key\n' | sudo install -m 600 -o hermes -g hermes /dev/stdin /var/lib/hermes/env
```

After switching, check the managed service:

```bash
systemctl status hermes-agent
journalctl -u hermes-agent -f
hermes version
hermes config
```

With the official NixOS module, configuration is declarative in Nix. Do not use `hermes setup` on the server to mutate managed service config; update `services.hermes-agent.settings` in this repo instead.

### 6. Generate VPNBook WireGuard configs

Open:

```text
https://www.vpnbook.com/freevpn/wireguard-vpn
```

Generate several configs, preferably from different regions and ports. For example:

```text
us16-443.conf
us178-443.conf
ca149-443.conf
de20-443.conf
fr200-443.conf
```

Copy them to the server:

```bash
scp *.conf evgen2571@nixos-server:/tmp/
ssh evgen2571@nixos-server
sudo install -d -m 700 /etc/wireguard/vpnbook
sudo install -m 600 /tmp/*.conf /etc/wireguard/vpnbook/
sudo rm /tmp/*.conf
```

### 7. Dry-build, then switch

From the repo root on the server:

```bash
sudo nixos-rebuild dry-build --flake .#nixos-server
sudo nixos-rebuild switch --flake .#nixos-server
```

### 8. Verify VPN startup and failover

Check service status:

```bash
systemctl status vpnbook-wireguard.service
systemctl status vpnbook-wireguard-check.timer
sudo vpnbook-wg status
```

Check public IP through the VPN interface:

```bash
curl --interface vpnbook0 https://ifconfig.me
```

Force a switch to the next config:

```bash
sudo vpnbook-wg switch
sudo vpnbook-wg status
```

## Updating expired VPNBook configs

Because configs expire after 7 days, make this a weekly habit:

1. Generate new configs on VPNBook.
2. Copy them to `/etc/wireguard/vpnbook`.
3. Remove old expired configs.
4. Restart or switch the VPN service.

Example:

```bash
sudo install -m 600 ~/new-vpnbook-configs/*.conf /etc/wireguard/vpnbook/
sudo rm /etc/wireguard/vpnbook/old-expired-*.conf
sudo systemctl restart vpnbook-wireguard.service
sudo vpnbook-wg status
```

## Best practices

- Do not commit `.conf` files containing WireGuard private keys.
- Keep multiple configs in `/etc/wireguard/vpnbook` so failover has alternatives.
- Prefer ports 443 and 80 if the network blocks unusual UDP ports.
- Be careful with remote servers: VPNBook WireGuard configs are usually full-tunnel configs. When the VPN comes up, default outbound routing may move through the VPN and can break ordinary public-IP SSH return traffic from a remote VPS/VM. Since you use Tailscale, prefer SSH over Tailscale (`ssh evgen2571@nixos-server` via MagicDNS or the `100.x.y.z` tailnet IP) and keep provider console/recovery access for the first test.
- Keep SSH access independent of the VPN. Do not require VPN to SSH into the server unless you have console access.
- Keep a console/recovery path before enabling strict firewall or SSH settings.
- Use `sudo nixos-rebuild dry-build --flake .#nixos-server` before `switch`.
- Keep server-specific hardware config in `hosts/server/hardware-configuration.nix`, generated on the actual server.

## Files added for this setup

```text
hosts/server/configuration.nix
hosts/server/hardware-configuration.nix
hosts/server/profile.nix
modules/system-services/vpnbook-wireguard-failover.nix
docs/server-wireguard-vpnbook.md
```
