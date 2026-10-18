# CodeGraph in my-nixos

[CodeGraph](https://github.com/colbymchenry/codegraph) is a local source-code
knowledge graph and MCP server. The existing `nixpkgs-unstable` flake input
provides its Nix package at the pinned revision.

`modules/user-ai/codegraph.nix` installs only that package. Both
`nixos-pc` and `nixos-lp` enable it; the server does not. It does not
automatically register an MCP, add agent instructions, run a daemon, or index
projects. No extra flake input or custom package is needed.

CodeGraph installation is **declarative**. Its runtime configuration, MCP
selection and per-project indexes remain **mutable** without rebuilding NixOS.
When updating the executable itself, update the pinned Nixpkgs input and rebuild
normally. Avoid `codegraph upgrade` for the Nix-managed executable.

## First check (after activating the host)

```sh
codegraph --help
codegraph --version
```

## Connect it to Codex through Skillshare

Only after initializing Skillshare and reviewing your existing MCP list, add a
portable MCP entry. It should be managed in one place; do not also run
`codegraph install` for the same Codex target because that command can modify
native MCP configuration and instructions independently of Skillshare.

```sh
skillshare mcp list
skillshare mcp add codegraph --target codex -- codegraph serve --mcp
skillshare sync mcp --dry-run
# Review the preview and resolve any ownership conflicts first:
skillshare sync mcp
codex mcp list
```

To manage the entry through the interactive dashboard instead, run
`skillshare ui` and add a local stdio server:

- Name: `codegraph`
- Command: `codegraph`
- Arguments: `serve`, `--mcp`
- Target: `codex`

Skillshare writes the native Codex MCP configuration only when you sync.
Restart Codex after changing MCP settings; existing running sessions do not reliably hot-reload their MCP configuration. Orca integrations may require separate target-specific configuration; do not assume all agents read Codex's MCP list.

To keep CodeGraph out of every project by default, use project-scoped Skillshare
configuration instead of the global command above. In the target repository,
initialize Skillshare project mode, add the MCP there, then preview and sync
with project scope. Codex will load local MCP definitions only for trusted
projects. **Codex does not support disabling a globally defined MCP with a
project-local Skillshare override**, so choose either global or per-project
ownership deliberately.

To temporarily disable globally managed CodeGraph, change its receiving
targets to `none` in Skillshare, sync MCP, and restart your Codex session.
Do not uninstall the binary to toggle MCP availability.

## Index a project

From any code repository:

```sh
codegraph init
```

This writes a local `.codegraph/` index and starts watching project changes
when connected to a supporting session. Check whether generated indexes are
ignored by Git; keep them out of commits. The graph is per-project, so
initializing one repository does not automatically index all other projects.

Removing the index is independent of the executable and MCP registration:
`codegraph uninit` removes the project's index.

## Safety

- No Home Manager-managed `~/.codex/config.toml` or `AGENTS.md` is added.
- The module leaves Codex login state, plugins, and VPN routing under their existing owners.
- CodeGraph also has a separate upstream installer that edits Agent files;
  it is **not** run during Nix activation.
- The package comes from the existing locked `nixpkgs-unstable` input. Its
  availability and source version were verified at the lockfile revision,
  but actual NixOS builds and CodeGraph MCP handshakes must be tested on
  your PC or laptop.
