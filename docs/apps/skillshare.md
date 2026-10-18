# Skillshare

Skillshare manages writable agent skills, MCP definitions and supported plugins.
Nix installs the CLI on both desktops. Changing those resources does not require
a NixOS rebuild; updating the executable does.

Start with `skillshare version` and `skillshare --help`. To try project mode away
from your global setup:

```sh
mkdir -p ~/dev/skillshare-test
cd ~/dev/skillshare-test
skillshare init -p --targets codex
skillshare install anthropics/skills/skills/frontend-design -p
skillshare sync -p --dry-run
```

Review conflicts before running `skillshare sync -p`. `skillshare ui` opens the
dashboard. Back up existing global resources and inspect managed symlinks before
adopting them. Do not overwrite unmanaged skills or remove login state to resolve
an ownership conflict. Repository maintenance skills are linked from
[AGENTS.md](../../AGENTS.md).

## Ownership

[modules/user-ai/skillshare.nix](../../modules/user-ai/skillshare.nix) installs
only the executable from [pkgs/skillshare.nix](../../pkgs/skillshare.nix).
Home Manager does not initialize Skillshare, create targets, or run sync/upgrade.
It does not own Skillshare's mutable configuration or account-managed plugins.

New agent sessions may be needed after MCP or plugin changes. Syncing files does
not reconfigure an already-running session. Codex authentication and mutable
configuration remain in the home directory. Codex uses its VPN launcher;
ordinary Orca uses host networking and `orca-vpn` explicitly opts into isolation.

For a local source graph, see [CodeGraph](codegraph.md).
[Upstream documentation](https://skillshare.runkids.cc/docs) covers resource
management; use [deployment](../operations/deployment.md) for package updates.
