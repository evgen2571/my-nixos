# M02 validation evidence

Implementation of issue #29 against the approved M01 contract, 2026-10-18.
Baseline: `pre-cleanup-history`. Nix 2.34.8,
x86_64-linux. All commands ran without real-host activation.

## Baseline and parity

Before configuration edits, evaluated all three real hosts' derivation paths and
selected semantics: state versions, loader/kernel settings, filesystems/swap,
user policy/SSH, SOPS metadata excluding source path, full namespace options,
firewall, systemd service settings/dependencies, Home Manager state/session and
managed file targets. Credentialed after-values match baseline for all three,
normalizing only Nix store hashes (not package names/versions or runtime paths).
Raw snapshots stay in a mode-0700 local evidence directory, outside either Git repo.
This is a bounded semantic comparison, not a claim that every possible option or
runtime application database was compared.

Seven encrypted/policy files copied to the verified-PRIVATE repository were
byte-identical before public HEAD removal. No decryption, rotation or rekey was
performed for relocation. Private source has no build outputs or package inputs.
Narrow project-pin overrides retain the copied values; public browser spaces,
force policies and mutable state ownership remain unchanged.

## Executed checks

- Public `nix flake show` and `nix flake check --no-build`; all three toplevel
  derivation evaluations without a private checkout input or age identity.
- Full public and private-input registered flake checks, including existing namespace/systemd VM,
  scripts, recovery, synthetic module, Niri and config-path checks.
- Credentialed non-activating PC/laptop/server toplevel builds.
- Patched nixos-rebuild package build with 62 passing upstream/regression tests;
  actual `nixos-rebuild dry-build` with private override and `--no-write-lock-file`.
- Secretless production toplevel build refused with the intended missing-private
  error. Selector tests cover explicit none/local/private, stale unselected source,
  missing files, malformed maps, null entries and override-without-ciphertext.
- Inert `just` and Fish tests preserve trailing flags, including a private checkout
  path containing a space. No deployment command double performs live work.
- `tests/migration/standalone.sh`: clean tracked-source fixture with empty nested
  input and unchanged lock; copied host built in none and single-repository local
  SOPS modes with synthetic hardware/public login key and runtime-generated test
  identities kept outside Git/store. Missing encrypted field and first-login
  configuration rejected. Local recipient-policy build check passed.
- Disposable template VM accepted key-only SSH login. The actual guard, executed
  as root in that guest, accepted synthetic valid identity/ciphertext and refused
  unsafe permissions, a wrong identity and a missing identity. No real host key
  or credential was used. Normal local metadata tests skip their root-only case;
  the guest exercises that boundary.
- Selected-source validation runs independently of consumers; negative tests reject
  plaintext, malformed age metadata and missing encrypted data even with no secret
  declarations. Local policy tests reject unmatched/malformed policy and broadened
  or reduced recipient scope without including document values in diagnostics.
- Standards/spec reviews identified host-name branching and missing source-level
  validation for zero consumers; both were corrected and regression-checked.
- Clean committed public clone evaluates all hosts without private access. Pinned
  git+file private override evaluates successfully and public lock stays byte-identical.
- Changed Nix files formatted; changed documentation links and `git diff --check`.

## Operational limits

No real install, switch, boot selection, network/service restart, real provider
health/egress test, identity inspection or publication audit was performed. No
live first-access, server suspend/resume or rollback exercise is implied.

Use the target's rebuild with normal re-exec and the target's guarded installer,
not old install-media tools or explicit bypass flags; see [installation](installation.md).
The native pre-switch hook alone runs too late to guard profile selection, hence
the tested rebuild patch. Installer integration is built and inspected; no disks
were installed. Private input visibility stays PRIVATE; history publication still
requires issue #31. Later deployment needs operator approval, protected identities,
source access under sudo/on the target, independent console/SSH and recovery planning.
