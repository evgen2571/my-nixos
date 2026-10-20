#!/usr/bin/env bash
set -euo pipefail

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
    else
        private_checkout=$(git -C "$private_input" rev-parse --show-toplevel)
        private_status=$(git -C "$private_checkout" status --porcelain)
        if [[ -n $private_status ]]; then
            echo 'Private checkout has uncommitted changes; commit or review them before rebuilding.' >&2
            exit 1
        fi
        private_rev=$(git -C "$private_checkout" rev-parse HEAD)
        # Encode path characters that would change the meaning of the Git URL.
        private_url=${private_checkout//%/%25}
        private_url=${private_url// /%20}
        private_url=${private_url//#/%23}
        private_url=${private_url//\?/%3F}
        private_flags=(--override-input private "git+file://$private_url?rev=$private_rev")
        echo "Using private commit $private_rev" >&2
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
exec sudo nixos-rebuild "$action" --flake ".#$host" "${private_flags[@]}" --no-write-lock-file "$@"
