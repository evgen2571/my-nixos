# Run: nix eval --impure --file lib/test-pdfcraft.nix
let
  flake = builtins.getFlake (toString ../.);
  lib = flake.inputs.nixpkgs.lib;
  inherit (flake.nixosConfigurations) nixos-pc nixos-lp;
  disabled = nixos-pc.extendModules {
    modules = [ { my.primaryUser.home.settings.my.user.apps.pdfcraft.enable = lib.mkForce false; } ];
  };
  home = host: host.config.home-manager.users.${host.config.my.primaryUser.name};
  installsPdfcraft = host: builtins.elem "pdfcraft" (map lib.getName (home host).home.packages);
  pdfDefault = host: (home host).xdg.mimeApps.defaultApplications."application/pdf" or [ ];
  desktopId = "ai.storyteller.pdfcraft.desktop";
in
assert installsPdfcraft nixos-pc && pdfDefault nixos-pc == [ desktopId ];
assert installsPdfcraft nixos-lp && pdfDefault nixos-lp == [ desktopId ];
assert !(installsPdfcraft disabled) && !(builtins.elem desktopId (pdfDefault disabled));
true
