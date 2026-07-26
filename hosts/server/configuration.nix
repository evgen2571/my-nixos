{ pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./profile.nix
    ../../modules/system-core/server.nix
    ../../modules/system-core/user.nix
  ];

  networking.hostName = "nixos-server";

  my.primaryUser = {
    enable = true;
    name = "operator";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    authorizedKeyFiles = [
      ../../keys/operator-pc.pub
    ];

    git = {
      userEmail = "150374952+evgen2571@users.noreply.github.com";
      signingKey = "~/.ssh/id_ed25519_github.pub";
    };
  };

  services.tailscale = {
    useRoutingFeatures = "client";
  };

  # Set to the NixOS release used for this server's initial installation.
  # Do not change during normal NixOS upgrades.
  system.stateVersion = "25.11";
}
