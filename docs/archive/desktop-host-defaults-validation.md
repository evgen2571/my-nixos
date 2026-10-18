# Shared desktop defaults validation (#17)

This record preserves the original comparison for the shared-profile extraction.
Its baseline and commands predate later private-input changes. These results
were not rerun for the documentation reorganization. Use the current
[selection inventory](../reference/desktop-host-defaults.md) and
[deployment procedure](../guides/deployment.md) for current work.

## Evaluated option comparison

The pre-edit baseline is commit `pre-cleanup-history`.
All three host matrices were equal before and after the extraction, including
Steam enabled on both desktop hosts. The comparison evaluates
`my.desktop`, `my.hardware`, `my.system`, and the primary user's evaluated
Home Manager `my.user` (the result of `my.primaryUser.home.settings`), plus
`networking.extraHosts`, public CA content hashes, greetd settings,
display-manager default session/packages, Niri and greetd/sudo PAM settings.
Derivations are represented by their derivation paths; certificate paths
are compared by content hash. No private key or secret contents are read.

The temporary matrix expression used for both captures was:

```nix
flake:
let
  lib = flake.inputs.nixpkgs.lib;
  normalize = value:
    if lib.isDerivation value then value.drvPath
    else if builtins.isPath value then builtins.hashFile "sha256" value
    else if builtins.isAttrs value then lib.mapAttrs (_: normalize) (builtins.removeAttrs value [ "_module" ])
    else if builtins.isList value then map normalize value
    else value;
  matrix = c: normalize {
    desktop = c.my.desktop or {};
    hardware = c.my.hardware or {};
    system = c.my.system or {};
    user = c.home-manager.users.${c.my.primaryUser.name}.my.user;
    extraHosts = c.networking.extraHosts;
    certificates = map (builtins.hashFile "sha256") c.security.pki.certificateFiles;
    session = {
      greetd = if c.services.greetd.enable then { inherit (c.services.greetd) enable settings; } else { enable = false; };
      displayManager = { inherit (c.services.displayManager) defaultSession sessionPackages; };
      niri = c.programs.niri or {};
      pam = lib.genAttrs (builtins.filter (name: builtins.hasAttr name c.security.pam.services) [ "greetd" "sudo" ]) (name: { inherit (c.security.pam.services.${name}) fprintAuth enableGnomeKeyring text; });
    };
  };
in lib.mapAttrs (_: host: matrix host.config) flake.nixosConfigurations
```

Capture before editing and again after staging new flake source files:

```sh
nix eval --impure --json --expr 'import /tmp/my-nixos-17/matrix.nix (builtins.getFlake (toString ./.))' > /tmp/my-nixos-17/before.json
# Repeat with after.json, then compare:
cmp /tmp/my-nixos-17/before.json /tmp/my-nixos-17/after.json
```

Validation completed without live activation:

- `cmp /tmp/my-nixos-17/before.json /tmp/my-nixos-17/after.json`: identical for all three hosts.
- Historical formatting result: `nix fmt` passed with explicit files. The former `hosts/common/example-development.nix` was subsequently removed by M02.5; rerun formatting against currently tracked files, not that archived command.
- `nix flake check --no-build`: passed (evaluation only).
- `nix flake check`: passed (all registered flake checks).
- `nix build .#nixosConfigurations.nixos-pc.config.system.build.toplevel .#nixosConfigurations.nixos-lp.config.system.build.toplevel --no-link`: passed for both desktops.
- `git diff --check` and relative documentation link validation: passed.

No host activation, service restart, runtime/UI check or Steam runtime test was
performed. The laptop Steam runtime issue remains tracked separately in #16.
