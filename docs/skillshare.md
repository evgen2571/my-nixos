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

The existing `agent-toolkit` integration still manages global Codex skills,
some Codex launcher arguments, Serena, Ponytail preparation, and global
instructions. **Do not use Skillshare to sync to those same global Codex paths
yet.** Skillshare and Home Manager must not both own the same files. Preserve
Codex authentication, unrelated MCP configurations, account-managed plugins,
and the VPN namespace launcher. A later explicit migration should retire only
the conflicting parts of the toolkit after ownership and rollback checks.

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

Review the sync output **before** running `skillshare sync -p`. For this first
test, avoid global initialization/targets and any operation that would rewrite
Home Manager-owned files. `skillshare ui` opens the dashboard.

Use Skillshare to make runtime resource changes after ownership is established.
New Codex sessions are normally needed to observe changes to MCP or plugin
configuration; changing resources is not the same as hot-reconfiguring an
already-running session.

## Build, activate and check

The private `agent-toolkit` input in `my-nixos` must already be accessible and
`flake.lock` must include the required inputs (see `docs/agent-toolkit.md`).
Build on a machine that can access those private inputs.

```sh
nix build .#nixosConfigurations.nixos-pc.config.system.build.toplevel --no-link
nix build .#nixosConfigurations.nixos-lp.config.system.build.toplevel --no-link

# On the corresponding host only:
sudo nixos-rebuild switch --flake .#nixos-pc
# or, on the laptop:
sudo nixos-rebuild switch --flake .#nixos-lp

skillshare version
```

The release tarball is fixed by SHA-256, derived from the upstream maintainer's
published Homebrew formula. Updating the **Skillshare executable** is a Nix
package revision and requires normal activation; changing its managed agent
resources does not.

Upstream: https://github.com/runkids/skillshare
Documentation: https://skillshare.runkids.cc/docs
