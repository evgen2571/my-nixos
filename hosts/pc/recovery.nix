{ ... }:
{
  # Provision outside Git before installation; console login survives SOPS failure.
  users.users.root.hashedPasswordFile = "/var/lib/nixos/recovery-password";
}
