#!/usr/bin/env bash
set -euo pipefail

urlencode_path() {
    local path=$1 encoded='' character escaped index
    local LC_ALL=C

    # Encode UTF-8 bytes, keeping directory separators intact.
    for ((index = 0; index < ${#path}; index++)); do
        character=${path:index:1}
        case $character in
            [a-zA-Z0-9/._~-]) encoded+=$character ;;
            *)
                printf -v escaped '%%%02X' "'$character"
                encoded+=$escaped
                ;;
        esac
    done

    printf '%s' "$encoded"
}

action=$1
shift

private_flags=()
explicit_private=false
args=("$@")

for i in "${!args[@]}"; do
    if [[ ${args[i]} == --override-input && ${args[i+1]:-} == private ]]; then
        explicit_private=true
    fi
done

if [[ -n ${MY_NIXOS_PRIVATE:-} && $explicit_private == false ]]; then
    private_input=$MY_NIXOS_PRIVATE
    if [[ $private_input == git@github.com/* ]]; then
        private_input="git+ssh://$private_input"
    fi

    if [[ $private_input == git+ssh://* ]]; then
        [[ $private_input == *\?* ]] || private_input+='?ref=main'
        private_flags=(--override-input private "$private_input" --refresh)
        echo 'Using refreshed private SSH input' >&2
    elif private_checkout=$(git -C "$private_input" rev-parse --show-toplevel 2>/dev/null); then
        private_status=$(git -C "$private_checkout" status --porcelain)
        if [[ -n $private_status ]]; then
            echo 'Private checkout has uncommitted changes; commit or review them before rebuilding.' >&2
            exit 1
        fi
        private_rev=$(git -C "$private_checkout" rev-parse HEAD)

        private_url=$(urlencode_path "$private_checkout")
        private_flags=(--override-input private "git+file://$private_url?rev=$private_rev")
        echo "Using private commit $private_rev" >&2
    else
        if [[ -e $private_input/.git || -L $private_input/.git ]]; then
            echo 'Cannot inspect the private Git checkout; refusing to use it as an unfiltered directory.' >&2
            exit 1
        fi

        [[ -d $private_input && -f $private_input/flake.nix ]] || {
            echo 'Private source must be an existing flake directory or Git checkout.' >&2
            exit 1
        }

        private_path=$(realpath -- "$private_input")
        private_url=$(urlencode_path "$private_path")
        private_flags=(--override-input private "path:$private_url")
        echo 'Using private directory (all files must be safe for the Nix store)' >&2
    fi
fi

if [[ $action == check ]]; then
    exec nix flake check "${private_flags[@]}" --no-write-lock-file "$@"
fi

host=$1
shift

if [[ $action == build ]]; then
    exec nix build ".#nixosConfigurations.$host.config.system.build.toplevel" "${private_flags[@]}" --no-write-lock-file "$@"
fi

[[ $action != dry ]] || action=dry-build
exec nixos-rebuild "$action" --sudo --flake ".#$host" "${private_flags[@]}" --no-write-lock-file "$@"
