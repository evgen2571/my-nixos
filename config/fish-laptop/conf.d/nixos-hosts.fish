if status is-interactive
    function _nixos_repo_root
        if git rev-parse --show-toplevel >/dev/null 2>/dev/null
            git rev-parse --show-toplevel
        else
            pwd
        end
    end

    function _nixos_flake_cmd --argument-names action host
        set -l repo (_nixos_repo_root)
        if test -z "$host"
            echo "usage: $action <nixos-pc|nixos-lp|nixos-server>" >&2
            return 1
        end

        switch $action
            case build
                command nix build "$repo#nixosConfigurations.$host.config.system.build.toplevel"
            case dry
                command sudo nixos-rebuild dry-build --flake "$repo#$host"
            case switch
                command sudo nixos-rebuild switch --flake "$repo#$host"
            case boot
                command sudo nixos-rebuild boot --flake "$repo#$host"
            case '*'
                echo "unknown action: $action" >&2
                return 1
        end
    end

    function nb --description 'Build a NixOS host toplevel from the current repo'
        _nixos_flake_cmd build $argv[1]
    end

    function nd --description 'Dry-build a NixOS host from the current repo'
        _nixos_flake_cmd dry $argv[1]
    end

    function nsw --description 'Switch a NixOS host from the current repo'
        _nixos_flake_cmd switch $argv[1]
    end

    function nboot --description 'Build a NixOS boot generation from the current repo'
        _nixos_flake_cmd boot $argv[1]
    end
end
