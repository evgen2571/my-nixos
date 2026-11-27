# Run: nix eval --impure --file lib/test-luciole.nix
let
  flake = builtins.getFlake (toString ../.);
  lib = flake.inputs.nixpkgs.lib;
  inherit (flake.nixosConfigurations) nixos-pc nixos-lp;
  disabled = nixos-pc.extendModules {
    modules = [ { my.primaryUser.home.settings.my.user.files.luciole.enable = lib.mkForce false; } ];
  };
  home = host: host.config.home-manager.users.${host.config.my.primaryUser.name};
  packages = host: map lib.getName (home host).home.packages;
  folderDefault = host: (home host).xdg.mimeApps.defaultApplications."inode/directory" or [ ];
  revealService = "dbus-1/services/org.freedesktop.FileManager1.service";
  usesLuciole =
    host:
    builtins.elem "luciole" (packages host)
    && !(builtins.elem "dolphin" (packages host))
    && !(builtins.elem "yazi" (packages host))
    && folderDefault host == [ "dev.noctalia.luciole.desktop" ]
    && builtins.hasAttr revealService (home host).xdg.dataFile
    && host.config.services.gvfs.enable
    && builtins.elem "luciole" (home host).programs.noctalia.settings.theme.templates.builtin_ids
    && (home host).programs.noctalia.settings.widget.workspaces.monitors == [ "*" ];
in
assert builtins.all usesLuciole [
  nixos-pc
  nixos-lp
];
assert !(builtins.elem "luciole" (packages disabled));
assert !(builtins.elem "dev.noctalia.luciole.desktop" (folderDefault disabled));
assert !(builtins.hasAttr revealService (home disabled).xdg.dataFile);
"Both desktops use Luciole for folders and file reveals, with the Noctalia palette enabled"
