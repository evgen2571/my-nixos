# Updates and recovery

I build before I switch. It's easier to catch a broken expression or package build without changing the system I'm using.

From the repo:

```sh
git diff
nix flake check --no-write-lock-file
nix build --no-link .#nixosConfigurations.my-host.config.system.build.toplevel --no-write-lock-file
```

Replace `my-host` with your flake output. My existing PC/laptop/server builds need their matching private input. On those machines I normally use `just build-pc`, `just build-lp`, or `just build-server`, with `MY_NIXOS_PRIVATE` configured in a local `.env`. `just switch-*` activates a new generation; building alone doesn't.

For your own host, after checking the build:

```sh
sudo nixos-rebuild switch --flake .#my-host --no-write-lock-file
```

If you're changing boot, mounts, networking, SSH, login, secrets, or the VPN, have a working console or independent SSH path first. Keep a known-good generation and backups of anything writable. A successful build can't prove the machine will boot.

If the previous generation really was working, `sudo nixos-rebuild switch --rollback` can restore it; otherwise pick a known-good generation from the boot menu. Rolling back NixOS **doesn't** restore browser data, databases, encryption keys, or other mutable state.

I keep `system.stateVersion` and `home.stateVersion` stable during normal updates. To change inputs, update the lock deliberately, review the diff, and repeat the build/checks.

For a new machine's first installation, see [hosts](../hosts/README.md). For the full NixOS process, see the [upstream manual](https://nixos.org/manual/nixos/stable/).
