{ ... }:

{
  # Each host decrypts secrets with its existing SSH Ed25519 host key.
  # This private key must remain available before sops-nix activation runs.
  sops.age.sshKeyPaths = [
    "/etc/ssh/ssh_host_ed25519_key"
  ];
}
