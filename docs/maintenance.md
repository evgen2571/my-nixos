# Updates and recovery

I normally apply changes with `just switch <host>` from this checkout:

```sh
just switch nixos-pc
```

Use `nixos-lp` or `nixos-server` for the other machines. These commands act on the
machine you're running them on.

My hosts require their private input. I set `MY_NIXOS_PRIVATE` in a local `.env`;
a local private checkout must be clean and committed. See [secrets](secrets.md).

When I want to check without activating anything:

```sh
just check --no-build
just build nixos-pc
```

The first evaluates the flake; the second builds the host. Neither tests boot or
login. `just boot nixos-pc` prepares a generation for the next boot without
switching the running system.

Before changing boot, storage, networking, SSH, login, secrets, or the
[VPN](../modules/services/network-namespaces/README.md), keep a working console or
independent SSH path, a known-good generation, and data backups.

To restore a working previous generation, run `sudo nixos-rebuild switch --rollback`,
or choose a known-good generation from the boot menu. Rollback doesn't restore
browser data, databases, or keys.

I keep `system.stateVersion` and `home.stateVersion` unchanged during updates.
When updating inputs, review the lock diff and check the result.
