# M02.5 validation evidence

Issue #36; 2026-10-18, Nix 2.34.8, x86_64-linux. Declarative extraction only.
Fresh pre-edit option snapshots and toplevel derivation evaluations for PC,
laptop and server are protected outside both repositories (directory mode 0700).
The private remote was verified PRIVATE before copying selected metadata.

## Executed verification

- Credentialed before/after semantics match for all three hosts: primary account,
  evaluated UID/HOME/HM identity, password and sudo policy, Git/SSH settings,
  authorization, SOPS metadata/runtime paths, storage, VPN peers/routes/DNS/firewall,
  systemd service dependencies/settings, activation/file targets, browser profiles
  and active Noctalia settings. Comparison normalizes store hashes, compares public
  authorization-file contents after relocation, and parses the original Noctalia
  source TOML against the composed native settings. This is a bounded comparison,
  not an exhaustive proof of every Nix option or live runtime state.
- Public and explicit-private `nix flake show`, public/private full registered
  flake checks and clean public-only source evaluations of all three production
  toplevel derivations. `--no-write-lock-file` used; public lock byte-identical.
- Non-activating credentialed toplevel builds for server, laptop and PC.
- Focused metadata checks: arbitrary username reaches HM and mount path, Noctalia
  leaf override preserves unrelated settings, incomplete account/peer/SSH metadata
  is rejected, conflicting account declarations fail, production guards remain.
  The initial public-account regression failed before implementation and passed
  afterward. These checks use synthetic metadata, never real credentials.
- Dedicated shared VPN fixture runner and registered namespace/module/systemd,
  recovery, source-policy, helper, Niri and config-path checks.
- Standalone host template builds in none and local-SOPS modes with a different
  synthetic username, disposable VM key-only SSH login, negative first-access and
  missing-field cases. Synthetic identities remain outside Git/store. A first
  attempt lacked host `age`; rerunning with Nix-provided age/sops passed.
- Missing-private production build refuses with the existing deployment guard.
- Changed Nix formatting, local documentation links and both Git whitespace checks.

## Intentional differences and limits

Only source locations/hashes, Noctalia serialization and public-default metadata
change. Actual private-backed application settings, account/mount paths and host
behavior match the recorded baseline. New source revisions must be used as a
coordinated pair; older public revisions retain their prior private pin.

The inactive Noctalia v4 rollback JSON now composes narrow private identity leaves;
its installer remains disabled on production hosts. A sandbox test checks the
generated JSON and preserved ordinary settings. Hardware
UUIDs and generic browser workspace IDs remain deliberately public. See the
[metadata boundary](personal-metadata.md) for classification and rationale.

No activation, boot selection, install, service/network restart, real login/VPN
health check, secret decryption, credential rotation, history rewrite, merge or
visibility change. Runtime credentials, generated settings, logins and mutable
provider state were not extracted. Later deployment and publication need their
separate operator reviews; these static/VM checks do not establish live parity.
