{ config, pkgs, ... }:

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
      ../../keys/users/evgen2571/pc.pub
      ../../keys/users/evgen2571/laptop.pub
    ];

    git = {
      userEmail = "evgen.10.02.2008.83@gmail.com";
      signingKey = "~/.ssh/id_ed25519_github";
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

  # Suspend every night at 01:00. A separate wake-capable timer resumes
  # the machine at 06:00, provided the laptop firmware supports RTC wake.
  systemd.services.server-night-suspend = {
    description = "Suspend the server overnight";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.systemd}/bin/systemctl suspend";
    };
  };

  systemd.timers.server-night-suspend = {
    enable = config.my.system.services.networkNamespaces.namespaces.vpn.shared.role != "gateway";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 01:00:00";
      AccuracySec = "1min";
      Persistent = false;
    };
  };

  # The service itself does nothing. The timer exists to program a wake alarm.
  systemd.services.server-morning-wake = {
    description = "Morning wake timer target";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.coreutils}/bin/true";
    };
  };

  systemd.timers.server-morning-wake = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 06:00:00";
      AccuracySec = "1min";
      Persistent = false;
      WakeSystem = true;
    };
  };

  # Set to the NixOS release used for this server's initial installation.
  # Do not change during normal NixOS upgrades.
  system.stateVersion = "26.05";
}
