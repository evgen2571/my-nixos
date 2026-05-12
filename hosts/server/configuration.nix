{ modulePaths, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./profile.nix
    modulePaths.system.server
    modulePaths.system.user
  ];

  networking.hostName = "nixos-server";

  my.system.user = {
    enable = true;
    name = "operator";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    authorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA example"
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
    curl
    vim
    git
    tailscale
    wireguard-tools
  ];

  system.stateVersion = "25.11";
}
