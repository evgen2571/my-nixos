{ modulePaths, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./profile.nix
    modulePaths.system.server
    modulePaths.system.user
  ];

  networking.hostName = "nixos-server";

  my.primaryUser = {
    enable = true;
    name = "evgen2571";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    authorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKdP4G+8XLU9eQMnYJV7MCyJcWHb2xfDLFmbIdYKUI9O evgen2571-pc"
    ];

    git = {
      userEmail = "evgen.10.02.2008.83@gmail.com";
      signingKey = "~/.ssh/id_ed25519.pub";
    };
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  services.tailscale = {
    enable = true;
    useRoutingFeatures = "client";
  };

  networking.firewall = {
    allowedTCPPorts = [ 22 ];
    allowedUDPPorts = [ 41641 ];
    trustedInterfaces = [ "tailscale0" ];
  };

  environment.systemPackages = with pkgs; [
    curl
    vim
    git
    tailscale
    wireguard-tools
  ];

  system.stateVersion = "25.11";
}
