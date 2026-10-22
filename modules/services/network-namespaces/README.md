# Shared VPN

This is specific to my machines; don't enable it just because you're copying the desktop. The server is the Hide.me gateway, reached over Tailscale and WireGuard. Only selected app launches (like Codex and `orca-vpn`) use the isolated network. Normal desktop traffic, SSH, and Docker don't.

The important part is **fail-closed routing**. If the gateway, DNS, or tunnel is unavailable, isolated apps stay blocked. There's no fallback to the normal host connection.

From a normal host terminal:

```sh
vpn-status --verbose
sudo /etc/network-namespaces/vpn-check
```

Run those on the affected client. A client can't tell whether the provider account on the server needs attention; check the server separately. `AUTH_REJECTED` isn't proof of an expired account.

The implementation and recovery scripts are in this directory; `tests/network-namespaces/` has the isolated checks. Before changing networking, credentials, DNS, or the recovery timer, understand the existing firewall and namespace boundaries. Never bypass a blocked launch by unmasking old local-provider units or routing it through host DNS.

Rebuilding doesn't recover lost credentials. Keep independent server access and a known-good generation before any live maintenance.
