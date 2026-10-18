# CodeGraph

CodeGraph builds a local source-code graph. From the project you want to index:

```sh
codegraph --version
codegraph init
```

The per-project `.codegraph/` index should stay out of Git. Initializing one
repository does not index others. `codegraph uninit` removes that project's index;
it does not uninstall the executable or unregister MCP.

## Optional agent connection

Nix installs the CLI on both desktops through
[modules/user-ai/codegraph.nix](../../modules/user-ai/codegraph.nix), from the
locked unstable Nixpkgs input. It does not register MCP, start a daemon, edit
agent instructions or index projects. Avoid `codegraph upgrade` for this
Nix-managed binary.

If using [Skillshare](skillshare.md), review existing registrations before adding
CodeGraph. Choose one owner: `codegraph install` edits native agent settings
independently and can conflict with Skillshare.

For a globally managed Codex entry:

```sh
skillshare mcp list
skillshare mcp add codegraph --target codex -- codegraph serve --mcp
skillshare sync mcp --dry-run
```

Resolve conflicts, then run `skillshare sync mcp`, inspect `codex mcp list`, and
restart Codex. In the Skillshare dashboard, the equivalent stdio entry has
command `codegraph`, arguments `serve`, `--mcp`, and target `codex`. Orca may need
its own target configuration.

Choose project-scoped Skillshare setup if CodeGraph should be available only in
selected repositories. Codex loads local MCP definitions only for trusted
projects; a project override cannot disable a globally registered MCP. To disable
a global Skillshare entry, set its receiving targets to `none`, sync MCP and
restart the agent. Keep the binary installed.

CLI availability and an MCP handshake need checking on the target desktop.
A Nix evaluation alone does not establish either. Runtime configuration and
indexes remain writable without rebuilding NixOS. See
[upstream](https://github.com/colbymchenry/codegraph) for graph queries.
