#!/usr/bin/env bash
set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"

# Read only the public lock file; do not import the checkout or its ignored files.
exec nix --extra-experimental-features 'nix-command flakes' shell --impure --expr '
    let
        lock = builtins.fromJSON (builtins.readFile ./flake.lock);
        root = builtins.getAttr lock.root lock.nodes;
        nixpkgs = builtins.getAttr root.inputs.nixpkgs lock.nodes;
        source = builtins.fetchTree nixpkgs.locked;
        pkgs = import source.outPath { system = builtins.currentSystem; };
    in
        pkgs.python3.withPackages (ps: [ ps.pyyaml ])
' --command python3 lib/setup.py "$@"
