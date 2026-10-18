# Copy to hosts/<name>/ and generate hardware-configuration.nix for that machine.
{ config, lib, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./profile.nix
    ../../modules/system-core/user.nix
  ];

  networking.hostName = "replace-me";
  # Choose bootloader/firmware, mounts, networking and timezone for YOUR machine.
  system.stateVersion = "26.05";
  my.primaryUser = {
    enable = true;
    name = "operator";
    extraGroups = [ "wheel" ];
    home.settings.home.stateVersion = "26.05";
    # Supply your own SSH PUBLIC key before evaluation/installation.
    authorizedKeys = [ ];
  };
  users.mutableUsers = false;
  users.users.${config.my.primaryUser.name}.hashedPassword = "!";
  services.openssh = {
    enable = true;
    openFirewall = false;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };
  assertions = [
    {
      assertion =
        config.networking.hostName != "replace-me"
        && config.my.primaryUser.authorizedKeys != [ ]
        && lib.any (
          port:
          builtins.elem port config.networking.firewall.allowedTCPPorts
          || lib.any (i: builtins.elem port i.allowedTCPPorts) (
            builtins.attrValues config.networking.firewall.interfaces
          )
        ) config.services.openssh.ports;
      message = "New host: choose a hostname, your SSH public key and explicit reachable SSH firewall policy before installation.";
    }
  ];
}
