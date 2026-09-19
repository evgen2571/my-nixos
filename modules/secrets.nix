{ ... }:

{
  # Each host gets a dedicated age identity on its first activation.
  sops.age = {
    keyFile = "/var/lib/sops-nix/key.txt";
    generateKey = true;
  };
}
