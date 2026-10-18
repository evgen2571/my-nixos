# Find the cause before changing the host

Start from an ordinary host terminal. A VPN-isolated agent shell has different
network access, and rebuilding repeatedly won't fix missing runtime credentials
or a powered-off gateway. Keep console or independent SSH access available while
you investigate.

| Symptom | Check first | Continue with |
| --- | --- | --- |
| A new file seems absent during evaluation | `git status --short` and `git ls-files PATH`; Git flakes omit untracked files | [Register and build](../getting-started/installation.md#3-register-and-build) |
| The host template refuses evaluation | Hostname, SSH public key, and explicit reachable SSH firewall policy | [First access](../getting-started/installation.md#2-choose-hardware-features-and-first-access) |
| An option doesn't exist | Whether the host uses the intended desktop/server catalog; whether a helper belongs behind `default.nix` | [Module discovery](../development/modules.md#how-a-feature-reaches-a-host) |
| A production build says private input is required | Reviewed input pair and explicit `--override-input`; don't change the host to `none` | [Deployment guards](../guides/deployment.md#deployment-guards) |
| A SOPS or deployment preflight fails | Correct ciphertext source, original protected host identity, ownership/modes, and recipient policy | [Secret identities](../reference/secrets.md#identities-and-recipient-policy) and [restore](../guides/deployment.md#restore-an-existing-host) |
| A new host boots but SSH fails | Console access, configured username/key, network address, SSH port, and firewall interface | [Install and verify access](../getting-started/installation.md#4-install-and-verify-access) |
| VPN applications are blocked | `vpn-status --verbose` on each relevant host; clients can't diagnose the server's provider account | [VPN status and reason codes](../guides/shared-vpn-gateway.md#resilience-and-day-to-day-diagnosis) |
| Greeter appearance or keyring is wrong | Sync status and `journalctl -b -u greetd`; password/keyring mismatch | [Greeter diagnosis](../guides/noctalia-greeter.md) |
| Neovim kernel, LSP, or plugins are unavailable | Project environment, `:Lazy restore`, `:checkhealth molten`, `:LspInfo`, `:ConformInfo` | [Neovim workflow](../guides/neovim-research.md) |
| Browser settings don't apply | Selected profile, whether Zen was closed, and which files are declarative | [Zen profiles](../guides/zen-browser.md) |

`PATH` above means the repository path you expected Nix to see. Check metadata
without printing secrets. Don't publish raw provider logs, decrypted values,
private keys, or authentication files in a bug report.

For services, `systemctl --failed` and `systemctl status UNIT --no-pager` can
identify the failing unit; replace `UNIT` with the service you are investigating.
Read its logs privately before deciding on a repair. A service restart, VPN reset,
mask change, disk operation, or rollback changes runtime state and belongs to a
planned operator action, with separate authorization for agents.
