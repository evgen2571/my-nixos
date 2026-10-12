# Codex agent toolkit

The desktop and laptop use the same pinned `agent-toolkit` and `serena`
sources. `modules/user-ai/agent-toolkit.nix` imports the toolkit's Home
Manager module on desktop profiles, not on the server.

- Third-party skills are globally selected, never installed into project repos.
- Each repository's `.agents/skills` is reserved for its custom skills.
- Global `~/.codex/AGENTS.md` and Serena MCP arguments are Home Manager-managed.
- Both the native CLI and T3 Code use the existing Codex VPN-namespace wrapper.
- Ponytail's marketplace is prepared but not installed/trusted automatically.
  Review hooks in `/hooks` before switching `ponytail.mode` to `"lite"`.
- The complete account Superpowers plugin is still enabled; declaring it as
  `existingPlugins` suppresses duplicate standalone skills. Follow the
  toolkit's documented migration once a supported account disable control exists.

## Lock inputs from an SSH-authenticated machine

The `agent-toolkit` repository is private. Its exact Git revision and the
Serena revision are fixed in `flake.nix`, but **the new inputs must still be
recorded in `flake.lock`** on a machine with private GitHub SSH access:

```sh
# In your my-nixos checkout, as your normal user:
nix flake lock
git add flake.lock
git commit -m "build: lock agent toolkit and serena inputs"
```

Once this lock commit is shared, other hosts must use the same checked-in
`flake.lock` instead of resolving fresh inputs. Do not put SSH keys, tokens,
Codex auth, or hook approvals in Git. If a root-owned rebuild cannot fetch the
private input, first fetch/build it from your user account, or provide access
to the existing SSH agent temporarily. Do not copy private keys to root.

## Build and activate

From `my-nixos`, after locking:

```sh
nix build .#nixosConfigurations.nixos-pc.config.system.build.toplevel --no-link
nix build .#nixosConfigurations.nixos-lp.config.system.build.toplevel --no-link
```

Activate the matching host only:

- Desktop: `sudo nixos-rebuild switch --flake .#nixos-pc`
- Laptop: `sudo nixos-rebuild switch --flake .#nixos-lp`

Home Manager's ownership handoff is designed to remove only previously
toolkit-managed imperative global links; unmanaged conflicts cause activation
to stop. Inspect those conflicts rather than forcing an overwrite.

## Runtime checks on each host

Start fresh Codex and T3 Code processes, then check:

```sh
codex --version
codex mcp list
readlink ~/.codex/AGENTS.md
```

Inspect `/skills` and `/hooks` in Codex. Confirm Serena can perform a real
`find_symbol` in a supported Python or Rust project. Check Codex in both its
native CLI and T3 Code, including your VPN namespace. No remote repository
test can establish host activation, language-server readiness or hook trust.

For an update, change the pinned revisions intentionally, regenerate and
commit `flake.lock`, build both hosts, and activate independently. Revert
the integration commit or use a previous NixOS generation to roll back.
