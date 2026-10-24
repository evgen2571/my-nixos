# Agent instructions

- Preserve existing user changes and stay within the requested scope.
- Inspect relevant sources before editing; follow the repository's structure and
  conventions.
- Never inspect, expose, or commit private keys, plaintext credentials, or
  decrypted secrets.
  Keep plaintext secrets out of Nix source, including private inputs that enter
  the Nix store.
- Preserve generated and writable state, including profiles, caches, databases,
  keys, and legacy runtime files.
- Keep this repository the build/deployment root. Preserve private-input guards
  and keep personal input URLs out of the public lock file.
- Get explicit permission before `switch`, `boot`, service restarts, live
  networking changes, or runtime migrations. Non-activating evaluation and builds
  are allowed.
- Run checks appropriate to the change without weakening them. Report actual
  results and unverified behavior; evaluation is not a build or runtime test.

## Skills

- [add-module](.agents/skills/add-module/SKILL.md): new optional NixOS or Home
  Manager features.
- [maintain-nixos](.agents/skills/maintain-nixos/SKILL.md): build, activation, or
  service debugging; deployment/recovery; changes involving VPN, boot, storage,
  networking, authentication, or secrets.

Use both for new features with operational risks. Open matching files directly
if local skill discovery is unavailable. Ordinary app configuration and
documentation wording edits need only the relevant files.

## Git

Follow the user's Git instructions. Otherwise, work on a feature branch, commit
focused changes with `type: lowercase description`, and open a PR. Do not merge
into main without explicit approval.
