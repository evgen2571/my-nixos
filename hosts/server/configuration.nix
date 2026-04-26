{ modulePaths, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./profile.nix
    modulePaths.system.common
    modulePaths.system.user
  ];

  networking.hostName = "nixos-server";

  my.system.user = {
    enable = true;
    name = "evgen2571";
    description = "Eugene A";
    shell = pkgs.fish;
    extraGroups = [
      "networkmanager"
      "wheel"
      "input"
      "git"
    ];
    authorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKdP4G+8XLU9eQMnYJV7MCyJcWHb2xfDLFmbIdYKUI9O evgen2571-pc"
    ];
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
    git
    vim
    wget
    curl
    tailscale
    wireguard-tools
  ];

  system.stateVersion = "25.11";
}
