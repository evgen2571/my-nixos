# Personal metadata ownership

Issue #36 changes declarative source ownership only. `my-nixos` retains all real
hosts, feature selection, Home Manager, dotfiles, networking and deployment logic.
The optional private input still exports only `nixosModules` and `secretFiles`.
Build from this repository with the explicit override in [installation](installation.md);
never record the personal input in the public lock. Merge the coordinated private
PR before this public change. Deploy reviewed paired revisions; older public
revisions must keep their previous pinned private input until both PRs land.

| Class | Decision |
| --- | --- |
| Public reusable configuration | Host roles, generic VPN subnets, DNS/firewall/isolation, layouts, packages, browser spaces/ordinary pins, hardware UUIDs, mount structure and boot remain public |
| Private identifying metadata | Account description/name, Git selection, personal SSH aliases/key associations, Tailscale endpoint/peer bindings, development aliases/CA trust, browser profile/project pins and active Noctalia identity/location/path leaves live in narrow private host modules |
| Encrypted/runtime secrets | Passwords, API/provider tokens and private keys stay encrypted or runtime-only; no decryption or rotation for extraction |
| Mutable state | Generated Noctalia settings/themes, browser sessions/logins, Neovim copied files and writable agent resources keep their existing owners |

Public production accounts default to `operator` with no personal SSH authorization.
The empty input still permits evaluation but refuses production builds/deployment,
locks desktop accounts and blocks transport/provider startup. Credentialed production
builds require an explicit existing account, valid peer/endpoint associations and
SSH authorization when SSH is enabled. Missing metadata must be corrected in the
private input; never bypass the deployment guard to install public defaults.

`modules/system-core/user.nix` remains the sole account/HM adapter and now imports
[home/default.nix](../home/default.nix). User-specific drive mount paths derive
from the primary account; the real override keeps their exact previous targets.
Newcomers choose a username, optional Git identity and safe first login using
[templates/host](../templates/host/README.md), with either `none` or local SOPS.

Active Noctalia TOML is parsed into native settings with default priority. Private
modules override only selected leaves; public bars/widgets and generated settings
are unchanged. Public paths derive from HM HOME as actual absolute strings, with
no assumption that TOML expands `$HOME` or `~`. The opt-in v4 rollback JSON uses the same narrow approach through
`my.user.desktop.noctalia.legacyConfig.settings`; private leaves preserve its
original paths/location. Its installer remains disabled on production hosts.
Do not treat this extraction as publication clearance.

### Private development CA

Keep the example development root CA certificate at `my-nixos-private/certs/example-dev-rootCA.pem`, at the root of the **private** repository rather than under its `hosts/` directory. The narrow `hosts/pc.nix` and `hosts/laptop.nix` private modules refer to `../certs/example-dev-rootCA.pem` via `security.pki.certificateFiles`; `hosts/server.nix` must not gain that trust. Preserve the certificate bytes and effective trust store when relocating it. The public repository contains neither that certificate nor a duplicate public copy. The signing key must never be committed.

Hardware UUIDs/device selectors and browser workspace/pin UUIDs are retained
intentionally: they are identifiers, not authentication material, and moving them
adds boot/storage or browser migration risk without improving this boundary.
Review optional hardware privacy changes in M05 (#32). Historical documents/Git
and repository-owner URLs retain provenance; publication/history review remains #31.
Runtime credentials, identities, active provider state, browser logins and generated
settings cannot safely be extracted into Nix/Git and were not inspected or copied.
