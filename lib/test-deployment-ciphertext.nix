# Run: nix-instantiate --eval --strict lib/test-deployment-ciphertext.nix
# A path in the script must retain a store dependency, not just a filename.
let
  deployment = import ../modules/deployment/nixos.nix {
    config = { };
    lib = {
      mkIf = _: value: value;
      getExe = application: application.text;
      boolToString = value: if value then "true" else "false";
      escapeShellArg = value: value;
    };
    pkgs = {
      writeShellApplication = application: application;
      coreutils = null;
      sops = null;
    };
    # Harmless fixture: only path retention is tested, never decryption.
    secretFile = ../secrets/README.md;
    secretSource = "private";
    requirePrivate = true;
  };
in
assert builtins.hasContext deployment.config.system.preSwitchChecks.privateMaterial;
true
