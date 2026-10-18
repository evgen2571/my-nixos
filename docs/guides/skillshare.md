# Skillshare on NixOS

Skillshare is packaged **only for this private my-nixos configuration** (currently
pinned to v0.25.8). The module lives in `modules/user-ai/skillshare.nix`; the
versioned binary derivation is `pkgs/skillshare.nix`.

Both desktop profiles enable `my.user.ai.skillshare.enable`; the server does
not. The package adds the `skillshare` CLI to PATH after the next host
activation. No separate public flake, overlay, upstream PR, or Skillshare
service is involved.

## Important ownership boundary

Home Manager installs **the CLI only**. It does not run `skillshare init`,
`sync`, or `upgrade`, create a target, or manage Skillshare's mutable
configuration. Changing Skillshare skills, MCP definitions, or supported plugins
later requires **no NixOS or Home Manager rebuild**.

The previous declarative agent-toolkit and Serena integration has been
removed from this configuration. Existing Codex authentication and mutable
configuration stay in the user's home directory. Codex continues to use the VPN namespace launcher; normal Orca runs on host networking and the explicit `orca-vpn` wrapper opts into isolation.

**Historical migration note:** on the first activation of the old agent-toolkit removal, Home Manager could remove the
symlinks it previously managed in `~/.agents/skills/`, `~/.codex/AGENTS.md`,
and `~/.local/share/agent-toolkit/ponytail-marketplace`. Before activation,
copy any content you want to retain to ordinary writable files (dereference
symlinks when copying). Home Manager does not delete your old external
`agent-toolkit` Git checkout or its source repository. Do not manually
delete unrelated Codex skills, configuration, authentication, or plugins.

Skillshare may manage global skills after the old Home Manager-owned symlinks
have been retired, but inspect existing paths and review its sync dry run
first. Avoid overwriting unmanaged resources. The account-installed
Superpowers plugin (if still enabled) remains account-managed and was **not**
uninstalled or disabled by removing NixOS integration.

## First test, after activation

```sh
skillshare version
skillshare --help
```

Try **project mode**, which is separate from the global Codex setup:

```sh
mkdir -p ~/dev/skillshare-test
cd ~/dev/skillshare-test
skillshare init -p --targets codex
skillshare install anthropics/skills/skills/frontend-design -p
skillshare sync -p --dry-run
```

Review the sync output **before** running `skillshare sync -p`. Once the
old managed links have been removed during activation, you may also try global
Skillshare resources, after backing up your live Codex configuration.
`skillshare ui` opens the dashboard.

Use Skillshare to make runtime resource changes after ownership is established.
New Codex sessions are normally needed to observe changes to MCP or plugin
configuration; changing resources is not the same as hot-reconfiguring an
already-running session.

## Build, activate and check

Neither `agent-toolkit` nor Serena is required to evaluate the flake.
Both inputs and their obsolete lock nodes have been removed.

```sh
nix build .#nixosConfigurations.nixos-pc.config.system.build.toplevel --no-link
nix build .#nixosConfigurations.nixos-lp.config.system.build.toplevel --no-link

# On the corresponding host only:
sudo nixos-rebuild switch --flake .#nixos-pc
# or, on the laptop:
sudo nixos-rebuild switch --flake .#nixos-lp

skillshare version
```

After activation, verify `codex --version` and `codex mcp list`. If Serena
was also configured independently in writable `~/.codex/config.toml`, remove
that entry explicitly only if you no longer want it. The removed declarative
launcher no longer registers Serena. Restart affected Codex or Orca sessions after resource changes.
Do not delete `~/.codex/auth.json`, other login state, or account plugins.

The release tarball is fixed by SHA-256, derived from the upstream maintainer's
published Homebrew formula. Updating the **Skillshare executable** is a Nix
package revision and requires normal activation; changing its managed agent
resources does not.

Upstream: https://github.com/runkids/skillshare
Documentation: https://skillshare.runkids.cc/docs

For local code structure search, see [CodeGraph and its optional MCP](codegraph.md).
