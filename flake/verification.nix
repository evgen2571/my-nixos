{ inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      shared = import ../tests/network-namespaces/shared.nix { inherit (inputs) nixpkgs; };
      standalone = import ../tests/network-namespaces/module.nix { inherit (inputs) nixpkgs; };
      runner = pkgs.writeShellApplication {
        name = "shared-vpn-test";
        text = ''
          exec ${pkgs.bash}/bin/bash ${../tests/network-namespaces/shared.sh} ${shared.tools} ${shared.fixtures}
        '';
      };
    in
    {
      checks = {
        module-style =
          pkgs.runCommand "module-style-checks"
            {
              nativeBuildInputs = [
                pkgs.nixfmt
                pkgs.deadnix
              ];
            }
            ''
              find ${../modules} -name '*.nix' -print0 | xargs -0 nixfmt --check
              nixfmt --check ${../lib/package-sources.nix}
              deadnix --fail ${../modules} ${../lib/package-sources.nix}
              touch $out
            '';
        sesh-project-list =
          pkgs.runCommand "sesh-project-list-checks"
            {
              nativeBuildInputs = [
                pkgs.bash
                pkgs.shellcheck
              ];
            }
            ''
              shellcheck ${../modules/user-dev/tmux/project-list.sh} ${../tests/sesh/project-list.sh}
              bash ${../tests/sesh/project-list.sh} ${../modules/user-dev/tmux/project-list.sh}
              touch $out
            '';
        personal-metadata = import ../tests/migration/metadata.nix {
          inherit pkgs;
          configurations = inputs.self.nixosConfigurations;
        };
        migration-sources =
          assert import ../tests/migration/sources.nix;
          pkgs.runCommand "migration-source-checks"
            {
              nativeBuildInputs = [
                (pkgs.python3.withPackages (ps: [ ps.pyyaml ]))
                pkgs.just
                pkgs.fish
                pkgs.git
                pkgs.shellcheck
              ];
            }
            ''
              mkdir -p lib
              cp ${../lib/check-sops-source.py} lib/check-sops-source.py
              cp ${../lib/nixos-command.sh} lib/nixos-command.sh
              mkdir -p config/fish/conf.d
              cp ${../config/fish/conf.d/nixos-hosts.fish} config/fish/conf.d/nixos-hosts.fish
              cp ${../justfile} justfile
              mkdir -p tests
              cp -r ${../tests/migration} tests/migration
              mkdir -p modules/deployment
              cp ${../modules/deployment/preflight.sh} modules/deployment/preflight.sh
              python3 tests/migration/preflight.py
              python3 tests/migration/helpers.py
              shellcheck lib/nixos-command.sh
              python3 tests/migration/policy.py
              touch $out
            '';
        niri-host-profiles = import ../tests/niri/hosts.nix {
          inherit pkgs;
          configurations = inputs.self.nixosConfigurations;
        };
        config-paths =
          assert import ../tests/config-paths { inherit (pkgs) lib; };
          pkgs.runCommand "config-paths-checks" { } ''
            test -x ${../config/niri/scripts/focus-or-launch}
            touch $out
          '';
        shared-vpn-host-profiles = import ../tests/network-namespaces/hosts.nix {
          inherit pkgs;
          configurations = inputs.self.nixosConfigurations;
        };
        shared-vpn-systemd = import ../tests/network-namespaces/systemd.nix {
          inherit pkgs;
          sopsNix = inputs.sops-nix;
        };
        shared-vpn-module = builtins.deepSeq shared.system shared.fixtures;
        standalone-vpn-module = builtins.deepSeq standalone.system standalone.launcher;
        shared-vpn-recovery =
          pkgs.runCommand "shared-vpn-recovery-checks"
            {
              nativeBuildInputs = [ pkgs.python3 ];
            }
            ''
              mkdir -p modules/system-services/network-namespaces
              cp ${../modules/system-services/network-namespaces/doctor.py} modules/system-services/network-namespaces/doctor.py
              # Keep the same repository-relative CLI test boundary in the sandbox.
              mkdir -p tests/network-namespaces
              cp ${../tests/network-namespaces/recovery.py} tests/network-namespaces/recovery.py
              python3 tests/network-namespaces/recovery.py
              touch $out
            '';
        shared-vpn-scripts =
          pkgs.runCommand "shared-vpn-script-checks" { nativeBuildInputs = [ pkgs.shellcheck ]; }
            ''
              shellcheck ${../tests/network-namespaces/shared.sh} ${../tests/network-namespaces/prepare-shared-rollback.sh} ${../modules/system-services/network-namespaces/migration}/*.sh
              touch $out
            '';
      };
      apps.shared-vpn-test = {
        type = "app";
        program = "${runner}/bin/shared-vpn-test";
      };
    };
}
