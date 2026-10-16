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
