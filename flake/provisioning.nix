{ inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      provision = pkgs.writeShellApplication {
        name = "provision-disk";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.util-linux
        ];
        text =
          builtins.replaceStrings
            [ "@disko@" "@layout@" ]
            [
              "${inputs.disko.packages.${pkgs.stdenv.hostPlatform.system}.disko}/bin/disko"
              "${../provisioning}/layout.nix"
            ]
            (builtins.readFile ../provisioning/provision-disk.sh);
      };
    in
    {
      packages.provision-disk = provision;
      apps.provision-disk = {
        type = "app";
        meta.description = "Explicitly provision a fresh system disk (destructive after confirmation)";
        program = "${provision}/bin/provision-disk";
      };
      checks.provisioning-guard =
        pkgs.runCommand "provisioning-guard-checks"
          {
            nativeBuildInputs = [
              pkgs.python3
              pkgs.bash
              pkgs.shellcheck
            ];
          }
          ''
            mkdir -p tests/provisioning provisioning
            cp ${../tests/provisioning/guard.py} tests/provisioning/guard.py
            cp ${../provisioning/provision-disk.sh} provisioning/provision-disk.sh
            python3 tests/provisioning/guard.py
            shellcheck provisioning/provision-disk.sh
            touch $out
          '';
      checks.provisioning-layouts =
        assert import ../tests/provisioning/layouts.nix {
          inherit (pkgs) lib;
          inherit (inputs) disko;
        };
        pkgs.runCommand "provisioning-layout-checks" { } "touch $out";
      checks.provisioning-hosts =
        assert import ../tests/provisioning/hosts.nix {
          configurations = inputs.self.nixosConfigurations;
          inherit (pkgs) lib;
        };
        pkgs.runCommand "provisioning-host-checks" { } "touch $out";
      checks.provisioning-pc = import ../tests/provisioning/vm.nix {
        inherit pkgs;
        inherit (inputs) disko;
        host = "pc";
      };
      checks.provisioning-laptop = import ../tests/provisioning/vm.nix {
        inherit pkgs;
        inherit (inputs) disko;
        host = "laptop";
      };
      checks.provisioning-server = import ../tests/provisioning/vm.nix {
        inherit pkgs;
        inherit (inputs) disko;
        host = "server";
      };
    };
}
