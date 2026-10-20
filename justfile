set positional-arguments
set shell := ["bash", "-uc"]
set dotenv-load

host := "nixos-pc"

default:
    @echo 'Use just --list to list recipes.'

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
    bash lib/nixos-command.sh build nixos-pc "$@"

dry-pc *flags:
    bash lib/nixos-command.sh dry nixos-pc "$@"

switch-pc *flags:
    bash lib/nixos-command.sh switch nixos-pc "$@"

build-lp *flags:
    bash lib/nixos-command.sh build nixos-lp "$@"

dry-lp *flags:
    bash lib/nixos-command.sh dry nixos-lp "$@"

switch-lp *flags:
    bash lib/nixos-command.sh switch nixos-lp "$@"

build-server *flags:
    bash lib/nixos-command.sh build nixos-server "$@"

dry-server *flags:
    bash lib/nixos-command.sh dry nixos-server "$@"

switch-server *flags:
    bash lib/nixos-command.sh switch nixos-server "$@"
