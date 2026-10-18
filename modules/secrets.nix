{
  config,
  lib,
  secretFile,
  secretSource,
  host,
  pkgs,
  ...
}:
let
  # Only encrypted source is inspected; runtime secret values never enter Nix.
  encrypted = if secretFile == null then "" else builtins.readFile secretFile;
  hasEncryptedKey =
    key:
    builtins.any (line: builtins.match (key + ": ENC[[]AES256_GCM,.+type:str[]]") line != null) (
      lib.splitString "\n" encrypted
    );
in
{
  assertions = lib.mapAttrsToList (_: secret: {
    assertion = secretFile != null && hasEncryptedKey secret.key;
    message = "Selected SOPS host source is missing an encrypted required field (check hosts/<host>/secrets.nix).";
  }) config.sops.secrets;
  system.checks = lib.optional (secretSource == "local" && secretFile != null) (
    pkgs.runCommand "local-sops-policy-${host}"
      {
        nativeBuildInputs = [ (pkgs.python3.withPackages (ps: [ ps.pyyaml ])) ];
      }
      ''
        python3 ${../lib/check-sops-policy.py} ${secretFile} ${../.sops.yaml} ${lib.escapeShellArg host}
        touch $out
      ''
  );
  sops.age = {
    keyFile = "/var/lib/sops-nix/key.txt";
    generateKey = true;
  };
}
