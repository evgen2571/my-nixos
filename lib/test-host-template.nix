# Run against a host copied from the template, with and without the guide's desktop:
# nix eval --impure .#nixosConfigurations.my-host --apply 'import ./lib/test-host-template.nix'
{ config, extendModules, ... }:
let
  user = config.my.primaryUser.name;
  home = config.home-manager.users.${user};
  withSSH =
    (extendModules {
      modules = [ { my.primaryUser.home.settings.my.user.dev.ssh.enable = true; } ];
    }).config.home-manager.users.${user};
in
assert config.system.build.toplevel.drvPath != "";
assert !config.users.mutableUsers;
assert config.users.users.${user}.hashedPasswordFile == "/var/lib/my-nixos/login-password";
assert config.users.users.${user}.hashedPassword == null;
assert config.security.sudo.enable && config.security.sudo.wheelNeedsPassword;
assert builtins.elem "wheel" config.users.users.${user}.extraGroups;
assert config.networking.networkmanager.enable;
assert !config.services.openssh.enable;
assert config.sops.secrets == { };
assert !home.programs.ssh.enable;
assert !(home.programs.ssh.settings ? "server");
assert withSSH.programs.ssh.enable;
assert withSSH.programs.ssh.settings.server.data.HostName == "nixos-server";
assert withSSH.programs.ssh.settings."github.com".data.IdentityFile == "~/.ssh/id_ed25519_github";
assert !config.my.hardware.nvidia.enable;
assert !config.my.system.services.networkNamespaces.enable;
assert !config.my.system.services.tailscale.enable;
assert !home.my.user.desktop.niriConfig.enable;
true
