# Host adaptation starting point

Copy this directory when you're adapting my module collection to your own
machine. Keep the existing PC, laptop, and server profiles for their original hosts.
Follow [New machine without secrets](../../docs/operations/installation.md#new-machine-without-secrets)
for copying, hardware generation, registration, first access and installation.

## Template boundaries

- [configuration.nix](configuration.nix) imports your generated
  `hardware-configuration.nix` and defines the account/access requirements.
  It refuses evaluation until you choose a hostname, SSH public key and reachable
  SSH firewall policy. Root and password login are locked.
- [profile.nix](profile.nix) is where you select features through existing `my.*`
  options. No maintainer-specific credentials or VPN are enabled by default.
- The primary-user adapter derives Home Manager identity and HOME. Optional Git
  identity belongs in `my.primaryUser.git`; enable `my.user.dev.git` through
  `my.primaryUser.home.settings` when wanted.

Optional credentials use the existing [SOPS workflow](../../docs/operations/secrets.md#single-repository-setup).
Do not copy another host's hardware declarations or personal identities.
