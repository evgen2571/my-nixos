{
  config,
  lib,
  pkgs,
  secretFile,
  secretSource,
  requirePrivate,
  ...
}:
let
  available = secretSource == "private" && secretFile != null;
  preflight = pkgs.writeShellApplication {
    name = "deployment-preflight";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.sops
    ];
    text =
      builtins.replaceStrings
        [ "@available@" "@ciphertext@" ]
        [
          (lib.boolToString available)
          (lib.escapeShellArg (if secretFile == null then "/dev/null" else toString secretFile))
        ]
        (builtins.readFile ./preflight.sh);
  };
in
{
  config = lib.mkIf requirePrivate {
    # This only suppresses NixOS's evaluation-time lockout assertion. Accounts
    # stay locked, and the unavailable closure below cannot be built/deployed.
    users.allowNoPasswordLogin = lib.mkIf (!available) true;
    # A secretless production closure must not reach nix-env, installers or boot.
    system.systemBuilderCommands = lib.mkAfter (
      if available then
        ''
          ln -s ${lib.getExe preflight} "$out/bin/deployment-preflight"
        ''
      else
        ''
          echo 'Deployment refused: existing host requires its private input; public evaluation is supported, deployment is unavailable' >&2
          exit 1
        ''
    );
    system.preSwitchChecks.privateMaterial = "${lib.getExe preflight}";
    system.build.nixos-install = lib.mkForce (
      pkgs.nixos-install.overrideAttrs (old: {
        src = pkgs.runCommand "nixos-install-preflight-source" { nativeBuildInputs = [ pkgs.patch ]; } ''
          cp ${old.src} nixos-install.sh
          chmod u+w nixos-install.sh
          patch -p1 < ${./install-preflight.patch}
          cp nixos-install.sh $out
        '';
      })
    );
    system.build.nixos-rebuild = lib.mkForce (
      (pkgs.nixos-rebuild-ng.override { nix = config.nix.package; }).overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [
          ./rebuild-preflight.patch
          ./rebuild-tests.patch
        ];
      })
    );
    # Retain the namespace/firewall and app isolation, but never start stale transports.
    systemd.services = lib.mkIf (!available) {
      netns-vpn-shared.serviceConfig.ExecCondition = lib.mkBefore [ "${pkgs.coreutils}/bin/false" ];
      hide-me-vpn =
        lib.mkIf (config.my.system.services.networkNamespaces.namespaces.vpn.shared.role == "gateway")
          {
            serviceConfig.ExecCondition = lib.mkBefore [ "${pkgs.coreutils}/bin/false" ];
          };
    };
  };
}
