{ ... }:

{
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.networkmanager.enable = true;

  time.timeZone = "UTC";
  i18n.defaultLocale = "en_US.UTF-8";

  nix.settings = {
    max-jobs = 1;
    cores = 2;
    eval-cache = true;
    min-free = 5368709120;
    max-free = 10737418240;
    keep-outputs = false;
    keep-derivations = false;
    substituters = [ "https://cache.nixos.org" ];
    experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  nix.gc = {
    automatic = true;
    dates = "Sun 12:00";
    persistent = false;
    randomizedDelaySec = "15min";
    options = "--delete-older-than 7d";
  };

  # A daily full-store optimisation is unnecessary on this small server and
  # can cause long, noisy disk activity. Run `sudo nix-store --optimise`
  # manually after unusually large upgrades if required.
  nix.optimise.automatic = false;

  systemd.services.nix-gc.serviceConfig = {
    Nice = 19;
    CPUSchedulingPolicy = "idle";
    IOSchedulingClass = "idle";
  };
}
