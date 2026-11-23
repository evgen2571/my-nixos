# Run: nix eval --impure --file lib/test-helium.nix
let
  flake = builtins.getFlake (toString ../.);
  lib = flake.inputs.nixpkgs.lib;
  enabled = flake.nixosConfigurations.nixos-pc;
  disabled = enabled.extendModules {
    modules = [ { my.primaryUser.home.settings.my.user.apps.helium.enable = lib.mkForce false; } ];
  };
  packages =
    host:
    map lib.getName host.config.home-manager.users.${host.config.my.primaryUser.name}.home.packages;
in
assert builtins.elem "helium" (packages enabled);
assert !(builtins.elem "google-chrome" (packages enabled));
assert !(builtins.elem "helium" (packages disabled));
"PC installs Helium instead of Chrome, and Helium can be disabled"
