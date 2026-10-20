set positional-arguments
set shell := ["bash", "-uc"]
set dotenv-load

host := "nixos-pc"

default:
    @just --list

fmt:
    nix fmt

check *flags:
    bash lib/nixos-command.sh check "$@"

build host=host *flags:
    bash lib/nixos-command.sh build "$@"

dry host=host *flags:
    bash lib/nixos-command.sh dry "$@"

switch host=host *flags:
    bash lib/nixos-command.sh switch "$@"

boot host=host *flags:
    bash lib/nixos-command.sh boot "$@"

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
