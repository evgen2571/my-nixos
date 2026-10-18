set positional-arguments
set shell := ["bash", "-uc"]

host := "nixos-pc"

default:
    @just --list

fmt:
    nix fmt

check:
    nix flake check

build host=host *flags:
    nix build ".#nixosConfigurations.$1.config.system.build.toplevel" "${@:2}"

dry host=host *flags:
    sudo nixos-rebuild dry-build --flake ".#$1" "${@:2}"

switch host=host *flags:
    sudo nixos-rebuild switch --flake ".#$1" "${@:2}"

boot host=host *flags:
    sudo nixos-rebuild boot --flake ".#$1" "${@:2}"

build-pc *flags:
    just build nixos-pc "$@"

dry-pc *flags:
    just dry nixos-pc "$@"

switch-pc *flags:
    just switch nixos-pc "$@"

build-lp *flags:
    just build nixos-lp "$@"

dry-lp *flags:
    just dry nixos-lp "$@"

switch-lp *flags:
    just switch nixos-lp "$@"

build-server *flags:
    just build nixos-server "$@"

dry-server *flags:
    just dry nixos-server "$@"

switch-server *flags:
    just switch nixos-server "$@"
