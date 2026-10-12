# Declarative Codex toolkit

Desktop and laptop use the same Git-pinned `agent-toolkit` Home Manager module
and Serena flake. The private toolkit source is a **non-flake** SSH input;
Serena's nixpkgs follows this repository's nixpkgs. Neither source has a moving
branch reference. Server configuration is unchanged.

The source-of-truth locations are:

- `flake.nix` and `flake.lock`: pinned toolkit and Serena sources
- `modules/user-ai/agent-toolkit.nix`: default skill selections, Serena, Ponytail
- `modules/user-ai/codex.nix`: Codex invocation and VPN namespace preservation
- `hosts/{pc,laptop}/profile.nix`: enablement on each workstation
- `agent-toolkit/skills/manifest.json`: revision-pinned third-party skills
- `agent-toolkit/agents/global/AGENTS.md`: shared agent instructions

Project `.agents/skills/` directories are exclusively for project-authored
skills. The optional global toolkit catalog is not part of Codex discovery.

## Lock inputs (required once for this branch)

`my-nixos/main` previously had neither input. Since the lock requires Nix
to resolve source content and the GitHub toolkit repository is **private**, do
this from a NixOS machine with GitHub SSH access. Do not invent narHash values.

```bash
cd ~/dev/my-nixos
git switch feat/declarative-agent-toolkit
ssh -T git@github.com
nix flake lock
git add flake.lock
git commit -m "build: lock codex toolkit sources"
```

The full input revisions are fixed in `flake.nix`; verify that `flake.lock`
records both `agent-toolkit` and `serena`. If your checkout is elsewhere,
use its real path. Commit the lock **before** considering this feature ready
to merge; otherwise Nix will need to resolve new inputs during first build.
Keep the two inputs pinned when updating other flake dependencies.

The toolkit Git revision must remain fetchable. SSH credentials are local,
not embedded in either repository.

## Build and activation

First inspect any imperatively installed skills. The toolkit's Home Manager
activation preflights collisions and migrates only verifiably toolkit-owned
symlinks. Unmanaged paths are not overwritten, even if Home Manager allows
backups. Resolve reported conflicts manually rather than deleting unknown files.

```bash
# Run on either machine after the lock commit is available
nix eval --raw .#nixosConfigurations.nixos-pc.config.system.build.toplevel.drvPath
nix eval --raw .#nixosConfigurations.nixos-lp.config.system.build.toplevel.drvPath
nixos-rebuild build --flake .#nixos-pc
nixos-rebuild build --flake .#nixos-lp
```

Build does not activate either host. Only after the builds succeed, activate
each machine **on that machine**:

```bash
# PC
sudo nixos-rebuild switch --flake .#nixos-pc
# Laptop
sudo nixos-rebuild switch --flake .#nixos-lp
```

These commands use your normal NixOS privilege/SSH setup. Do not copy Codex
`auth.json`, OAuth tokens, mutable `config.toml`, session files, or plugin
trust databases between machines. Existing T3 Code uses the same wrapped
Codex binary, and the VPN namespace launcher still owns the actual Codex
executable; toolkit arguments precede the user-provided arguments.

## Verify on each host

```bash
codex --version
codex mcp list
codex plugin list --json
readlink -f ~/.codex/AGENTS.md
ls -la ~/.agents/skills
```

Open a new Codex session and inspect `/skills` and `/hooks`. Verify Serena
with a real `find_symbol` operation in a supported language project; MCP
initialization alone does not prove language-server behavior. Check T3 Code
separately to confirm the same tool discovery and VPN routing.

The initial managed global selection is small. Superpowers remains an
account-managed plugin, so its three overlapping standalone skill copies
are suppressed by `existingPlugins = [ "superpowers" ]` until the full
account plugin can be disabled through a verified supported account control.
Do **not** uninstall the plugin or pretend its full skill bundle is gone.

Ponytail's local marketplace is prepared automatically and the launcher
selects `lite` **only if the plugin is already installed**. Hook trust and
plugin installation remain explicit per-machine actions, not reproducible
secrets to bake into Nix. Inspect any hooks in `/hooks` before approving them.
For a temporary off session, override the Codex plugin enable flag as
documented in the pinned toolkit README.

## Updating

Update `agent-toolkit` on its own branch, merge and publish its revision, then
change the toolkit `rev` in `my-nixos/flake.nix`, regenerate and commit
`flake.lock`, and rebuild each host. Optional global skill selections are
configured through `programs.agent-toolkit.profiles` and `skills` in the
reusable Home Manager module; do not use imperative `agent-toolkit global`
against managed Home Manager links.

Local authentication, plugin approval and live runtime smoke tests are
intentionally machine-specific. Everything else above is designed to be
reproducibly derived from the two Git repositories.
