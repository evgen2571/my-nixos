set positional-arguments

host := "nixos-pc"

default:
    @just --list

fmt:
    nix fmt

check:
    nix flake check

build host=host:
    nix build .#nixosConfigurations/{{host}}.config.system.build.toplevel

dry host=host:
    sudo nixos-rebuild dry-build --flake .#{{host}}

switch host=host:
    sudo nixos-rebuild switch --flake .#{{host}}

boot host=host:
    sudo nixos-rebuild boot --flake .#{{host}}

build-pc:
    just build nixos-pc

dry-pc:
    just dry nixos-pc

switch-pc:
    just switch nixos-pc

build-lp:
    just build nixos-lp

dry-lp:
    just dry nixos-lp

switch-lp:
    just switch nixos-lp

build-server:
    just build nixos-server

dry-server:
    just dry nixos-server

switch-server:
    just switch nixos-server
