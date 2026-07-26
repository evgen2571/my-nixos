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
    name = "server";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    authorizedKeyFiles = [
      ../../keys/evgen2571-pc.pub
      ../../keys/evgen2571-lp.pub
    ];

    git = {
      userEmail = "evgen.10.02.2008.83@gmail.com";
      signingKey = "~/.ssh/id_ed25519_github.pub";
    };
  };

  services.tailscale = {
    useRoutingFeatures = "client";
  };

  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
    HandleLidSwitchDocked = "ignore";
    IdleAction = "ignore";
  };

  systemd.targets = {
    sleep.enable = false;
    suspend.enable = false;
    hibernate.enable = false;
    hybrid-sleep.enable = false;
  };

  # Set to the NixOS release used for this server's initial installation.
  # Do not change during normal NixOS upgrades.
  system.stateVersion = "26.05";
}
